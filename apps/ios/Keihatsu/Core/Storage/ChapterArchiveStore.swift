import Foundation
import ImageIO

actor ChapterArchiveStore {
    enum ArchiveError: LocalizedError {
        case emptyChapter
        case missingPage(Int)
        case invalidArchive
        case unsupportedCompression

        var errorDescription: String? {
            switch self {
            case .emptyChapter: "A chapter cannot be archived without pages."
            case .missingPage(let page): "Downloaded page \(page) is missing or empty."
            case .invalidArchive: "The CBZ archive is incomplete or corrupt."
            case .unsupportedCompression: "This CBZ uses an unsupported compression method."
            }
        }
    }

    private struct Entry: Sendable {
        let name: String
        let compression: UInt16
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localHeaderOffset: UInt32
    }

    private struct WrittenEntry {
        let name: Data
        let crc: UInt32
        let size: UInt32
        let localOffset: UInt32
    }

    nonisolated let downloadsRoot: URL
    nonisolated let stagingRoot: URL
    nonisolated let documentsRoot: URL

    init(documentsRoot: URL? = nil, applicationSupportRoot: URL? = nil) {
        let documents = documentsRoot ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let support = applicationSupportRoot ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.documentsRoot = documents
        downloadsRoot = documents.appending(path: "downloads", directoryHint: .isDirectory)
        stagingRoot = support.appending(path: "Keihatsu/DownloadStaging", directoryHint: .isDirectory)
        Self.migrateLegacyDownloads(
            from: documents.appending(path: "Keihatsu/downloads", directoryHint: .isDirectory),
            to: downloadsRoot
        )
    }

    func stagingDirectory(for recordID: UUID) throws -> URL {
        let url = stagingRoot.appending(path: recordID.uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func stagedPageURL(recordID: UUID, pageIndex: Int) throws -> URL {
        try stagingDirectory(for: recordID).appending(path: String(format: "page%05d.download", pageIndex), directoryHint: .notDirectory)
    }

    func storeStagedDownload(_ temporaryURL: URL, recordID: UUID, pageIndex: Int) throws -> URL {
        let destination = try stagedPageURL(recordID: recordID, pageIndex: pageIndex)
        if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        guard ((try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) > 0 else {
            throw ArchiveError.missingPage(pageIndex + 1)
        }
        guard let source = CGImageSourceCreateWithURL(destination as CFURL, nil), CGImageSourceGetCount(source) > 0 else {
            try? FileManager.default.removeItem(at: destination)
            throw ArchiveError.missingPage(pageIndex + 1)
        }
        return destination
    }

    nonisolated func archiveURL(for identity: DownloadIdentity) -> URL {
        downloadsRoot
            .appending(path: safe(identity.sourceID), directoryHint: .isDirectory)
            .appending(path: safe(identity.mangaID), directoryHint: .isDirectory)
            .appending(path: "\(chapterComponent(identity.chapterID)).cbz", directoryHint: .notDirectory)
    }

    /// Writes a standards-compliant, uncompressed ZIP one file at a time. Image
    /// bytes are never accumulated in memory and the final CBZ appears atomically.
    func package(record: ChapterDownloadRecord) throws -> URL {
        guard !record.pages.isEmpty else { throw ArchiveError.emptyChapter }
        let ordered = record.pages.sorted { $0.index < $1.index }
        let sourceURLs: [(DownloadPageRecord, URL)] = try ordered.enumerated().map { offset, page in
            guard let filename = page.stagedFilename else { throw ArchiveError.missingPage(offset + 1) }
            let url = try stagingDirectory(for: record.id).appending(path: filename)
            guard FileManager.default.fileExists(atPath: url.path),
                  ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) > 0 else {
                throw ArchiveError.missingPage(offset + 1)
            }
            return (page, url)
        }

        let output = archiveURL(for: record.request.identity)
        try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
        let partial = output.appendingPathExtension("part")
        if FileManager.default.fileExists(atPath: partial.path) { try FileManager.default.removeItem(at: partial) }
        FileManager.default.createFile(atPath: partial.path, contents: nil)
        let handle = try FileHandle(forWritingTo: partial)
        defer { try? handle.close() }

        var writtenEntries: [WrittenEntry] = []
        for (offset, pair) in sourceURLs.enumerated() {
            let source = pair.1
            let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
            let size64 = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
            guard size64 > 0, size64 <= UInt32.max else { throw ArchiveError.missingPage(offset + 1) }
            let size = UInt32(size64)
            let crc = try crc32(of: source)
            let ext = imageExtension(for: source)
            let name = Data(String(format: "page%05d.%@", offset + 1, ext).utf8)
            let localOffset = UInt32(try handle.offset())
            try handle.write(contentsOf: localHeader(name: name, crc: crc, size: size))
            try copy(source, to: handle)
            writtenEntries.append(WrittenEntry(name: name, crc: crc, size: size, localOffset: localOffset))
        }

        let centralOffset = UInt32(try handle.offset())
        for entry in writtenEntries { try handle.write(contentsOf: centralHeader(entry)) }
        let centralSize = UInt32(try handle.offset()) - centralOffset
        try handle.write(contentsOf: endRecord(count: UInt16(writtenEntries.count), size: centralSize, offset: centralOffset))
        try handle.synchronize()
        try handle.close()

        let verified = try entries(in: partial)
        guard verified.count == ordered.count else { throw ArchiveError.invalidArchive }
        if FileManager.default.fileExists(atPath: output.path) { _ = try FileManager.default.replaceItemAt(output, withItemAt: partial) }
        else { try FileManager.default.moveItem(at: partial, to: output) }
        try? FileManager.default.removeItem(at: stagingRoot.appending(path: record.id.uuidString, directoryHint: .isDirectory))
        return output
    }

    func contains(_ identity: DownloadIdentity) -> Bool {
        let url = archiveURL(for: identity)
        guard FileManager.default.fileExists(atPath: url.path), let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else { return false }
        return (values.fileSize ?? 0) > 0 && ((try? entries(in: url).isEmpty) == false)
    }

    func readerPages(for chapter: ChapterIdentity) throws -> [ReaderPage] {
        let identity = DownloadIdentity(chapter: chapter)
        let archive = archiveURL(for: identity)
        guard FileManager.default.fileExists(atPath: archive.path) else { return [] }
        return try entries(in: archive).enumerated().map { index, entry in
            var components = URLComponents()
            components.scheme = "keihatsu-cbz"
            components.host = "page"
            components.queryItems = [
                URLQueryItem(name: "source", value: identity.sourceID),
                URLQueryItem(name: "manga", value: identity.mangaID),
                URLQueryItem(name: "chapter", value: identity.chapterID),
                URLQueryItem(name: "entry", value: entry.name)
            ]
            guard let url = components.url else { throw ArchiveError.invalidArchive }
            return ReaderPage(id: .init(chapter: chapter, index: index), imageURL: url, refererURL: nil)
        }
    }

    func data(for readerURL: URL) throws -> Data {
        guard readerURL.scheme == "keihatsu-cbz", let values = URLComponents(url: readerURL, resolvingAgainstBaseURL: false)?.queryItems else {
            throw ArchiveError.invalidArchive
        }
        func value(_ name: String) -> String? { values.first(where: { $0.name == name })?.value }
        guard let source = value("source"), let manga = value("manga"), let chapter = value("chapter"), let name = value("entry") else {
            throw ArchiveError.invalidArchive
        }
        let archive = archiveURL(for: DownloadIdentity(sourceID: source, mangaID: manga, chapterID: chapter))
        guard let entry = try entries(in: archive).first(where: { $0.name == name }), entry.compression == 0 else {
            throw ArchiveError.unsupportedCompression
        }
        let handle = try FileHandle(forReadingFrom: archive)
        defer { try? handle.close() }
        try handle.seek(toOffset: UInt64(entry.localHeaderOffset))
        let header = try read(handle, count: 30)
        guard header.uint32(at: 0) == 0x04034b50 else { throw ArchiveError.invalidArchive }
        let nameLength = Int(header.uint16(at: 26))
        let extraLength = Int(header.uint16(at: 28))
        let dataOffset = UInt64(entry.localHeaderOffset) + UInt64(30 + nameLength + extraLength)
        try handle.seek(toOffset: dataOffset)
        return try read(handle, count: Int(entry.compressedSize))
    }

    func delete(_ identity: DownloadIdentity) throws {
        let url = archiveURL(for: identity)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        removeEmptyParents(startingAt: url.deletingLastPathComponent())
    }

    func discardStaging(recordID: UUID) throws {
        let url = stagingRoot.appending(path: recordID.uuidString, directoryHint: .isDirectory)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    func storageSnapshot() -> DownloadStorageSnapshot {
        var count = 0
        var bytes: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: downloadsRoot, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) {
            for case let url as URL in enumerator where url.pathExtension.lowercased() == "cbz" {
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values?.isRegularFile == true else { continue }
                count += 1
                bytes += Int64(values?.fileSize ?? 0)
            }
        }
        let attributes = try? FileManager.default.attributesOfFileSystem(forPath: documentsRoot.path)
        let available = (attributes?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        return DownloadStorageSnapshot(archiveCount: count, byteCount: bytes, availableByteCount: available)
    }

    private func entries(in url: URL) throws -> [Entry] {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count >= 22 else { throw ArchiveError.invalidArchive }
        let lower = max(0, data.count - 65_557)
        var endOffset: Int?
        if data.count >= 4 {
            for offset in stride(from: data.count - 4, through: lower, by: -1) where data.uint32(at: offset) == 0x06054b50 {
                endOffset = offset
                break
            }
        }
        guard let endOffset else { throw ArchiveError.invalidArchive }
        let count = Int(data.uint16(at: endOffset + 10))
        var cursor = Int(data.uint32(at: endOffset + 16))
        var result: [Entry] = []
        for _ in 0..<count {
            guard cursor + 46 <= data.count, data.uint32(at: cursor) == 0x02014b50 else { throw ArchiveError.invalidArchive }
            let nameLength = Int(data.uint16(at: cursor + 28))
            let extraLength = Int(data.uint16(at: cursor + 30))
            let commentLength = Int(data.uint16(at: cursor + 32))
            guard cursor + 46 + nameLength + extraLength + commentLength <= data.count,
                  let name = String(data: data[(cursor + 46)..<(cursor + 46 + nameLength)], encoding: .utf8) else {
                throw ArchiveError.invalidArchive
            }
            if ["jpg", "jpeg", "png", "webp", "gif"].contains((name as NSString).pathExtension.lowercased()) {
                result.append(Entry(
                    name: name,
                    compression: data.uint16(at: cursor + 10),
                    compressedSize: data.uint32(at: cursor + 20),
                    uncompressedSize: data.uint32(at: cursor + 24),
                    localHeaderOffset: data.uint32(at: cursor + 42)
                ))
            }
            cursor += 46 + nameLength + extraLength + commentLength
        }
        return result.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    nonisolated private func safe(_ value: String) -> String {
        let forbidden = CharacterSet(charactersIn: "<>:\"/\\|?*")
        return value.components(separatedBy: forbidden).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private func chapterComponent(_ value: String) -> String {
        let withoutQuery = value.replacingOccurrences(of: "\\", with: "/").components(separatedBy: CharacterSet(charactersIn: "?#")).first ?? value
        let leaf = withoutQuery.split(separator: "/").last.map(String.init) ?? value
        let result = safe(leaf)
        return result.isEmpty ? "chapter" : result
    }

    private func imageExtension(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "webp", "gif"].contains(ext) { return ext }
        guard let handle = try? FileHandle(forReadingFrom: url),
              let signature = try? handle.read(upToCount: 12) else { return "jpg" }
        try? handle.close()
        if signature.starts(with: [0x89, 0x50, 0x4e, 0x47]) { return "png" }
        if signature.starts(with: [0x47, 0x49, 0x46]) { return "gif" }
        if signature.count >= 12, String(data: signature[0..<4], encoding: .ascii) == "RIFF",
           String(data: signature[8..<12], encoding: .ascii) == "WEBP" { return "webp" }
        return "jpg"
    }

    private func copy(_ source: URL, to output: FileHandle) throws {
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        while true {
            let data = try input.read(upToCount: 64 * 1_024) ?? Data()
            if data.isEmpty { break }
            try output.write(contentsOf: data)
        }
    }

    private func crc32(of url: URL) throws -> UInt32 {
        let input = try FileHandle(forReadingFrom: url)
        defer { try? input.close() }
        var crc: UInt32 = 0xffff_ffff
        while true {
            let data = try input.read(upToCount: 64 * 1_024) ?? Data()
            if data.isEmpty { break }
            for byte in data { crc = (crc >> 8) ^ Self.crcTable[Int((crc ^ UInt32(byte)) & 0xff)] }
        }
        return crc ^ 0xffff_ffff
    }

    private func localHeader(name: Data, crc: UInt32, size: UInt32) -> Data {
        var data = Data()
        data.appendLE(UInt32(0x04034b50)); data.appendLE(UInt16(20)); data.appendLE(UInt16(0)); data.appendLE(UInt16(0))
        data.appendLE(UInt16(0)); data.appendLE(UInt16(0)); data.appendLE(crc); data.appendLE(size); data.appendLE(size)
        data.appendLE(UInt16(name.count)); data.appendLE(UInt16(0)); data.append(name)
        return data
    }

    private func centralHeader(_ entry: WrittenEntry) -> Data {
        var data = Data()
        data.appendLE(UInt32(0x02014b50)); data.appendLE(UInt16(20)); data.appendLE(UInt16(20)); data.appendLE(UInt16(0)); data.appendLE(UInt16(0))
        data.appendLE(UInt16(0)); data.appendLE(UInt16(0)); data.appendLE(entry.crc); data.appendLE(entry.size); data.appendLE(entry.size)
        data.appendLE(UInt16(entry.name.count)); data.appendLE(UInt16(0)); data.appendLE(UInt16(0)); data.appendLE(UInt16(0)); data.appendLE(UInt16(0))
        data.appendLE(UInt32(0)); data.appendLE(entry.localOffset); data.append(entry.name)
        return data
    }

    private func endRecord(count: UInt16, size: UInt32, offset: UInt32) -> Data {
        var data = Data()
        data.appendLE(UInt32(0x06054b50)); data.appendLE(UInt16(0)); data.appendLE(UInt16(0)); data.appendLE(count); data.appendLE(count)
        data.appendLE(size); data.appendLE(offset); data.appendLE(UInt16(0))
        return data
    }

    private func read(_ handle: FileHandle, count: Int) throws -> Data {
        guard let data = try handle.read(upToCount: count), data.count == count else { throw ArchiveError.invalidArchive }
        return data
    }

    private func removeEmptyParents(startingAt url: URL) {
        var current = url
        while current.path.hasPrefix(downloadsRoot.path), current != downloadsRoot {
            guard let children = try? FileManager.default.contentsOfDirectory(atPath: current.path), children.isEmpty else { break }
            try? FileManager.default.removeItem(at: current)
            current.deleteLastPathComponent()
        }
    }

    nonisolated private static func migrateLegacyDownloads(from legacyRoot: URL, to downloadsRoot: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: legacyRoot.path) else { return }

        do {
            if !fileManager.fileExists(atPath: downloadsRoot.path) {
                try fileManager.moveItem(at: legacyRoot, to: downloadsRoot)
            } else {
                try mergeDirectory(from: legacyRoot, to: downloadsRoot, fileManager: fileManager)
            }
            removeDirectoryIfEmpty(legacyRoot.deletingLastPathComponent(), fileManager: fileManager)
        } catch {
            // A future launch can retry any legacy files that remain.
        }
    }

    nonisolated private static func mergeDirectory(from source: URL, to destination: URL, fileManager: FileManager) throws {
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        for item in try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey]) {
            let target = destination.appending(path: item.lastPathComponent)
            if (try item.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true {
                try mergeDirectory(from: item, to: target, fileManager: fileManager)
                removeDirectoryIfEmpty(item, fileManager: fileManager)
            } else if !fileManager.fileExists(atPath: target.path) {
                try fileManager.moveItem(at: item, to: target)
            } else {
                let sourceDate = (try? item.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let targetDate = (try? target.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                if sourceDate > targetDate {
                    try fileManager.removeItem(at: target)
                    try fileManager.moveItem(at: item, to: target)
                } else {
                    try fileManager.removeItem(at: item)
                }
            }
        }
        removeDirectoryIfEmpty(source, fileManager: fileManager)
    }

    nonisolated private static func removeDirectoryIfEmpty(_ url: URL, fileManager: FileManager) {
        guard let children = try? fileManager.contentsOfDirectory(atPath: url.path), children.isEmpty else { return }
        try? fileManager.removeItem(at: url)
    }

    private static let crcTable: [UInt32] = (0..<256).map { value in
        var crc = UInt32(value)
        for _ in 0..<8 { crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb8_8320 : crc >> 1 }
        return crc
    }
}

private extension Data {
    nonisolated mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }

    nonisolated func uint16(at offset: Int) -> UInt16 {
        guard offset + 2 <= count else { return 0 }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    nonisolated func uint32(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return UInt32(self[offset]) | (UInt32(self[offset + 1]) << 8) | (UInt32(self[offset + 2]) << 16) | (UInt32(self[offset + 3]) << 24)
    }
}
