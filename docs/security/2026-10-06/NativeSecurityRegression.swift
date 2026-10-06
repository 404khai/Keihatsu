// Compiled alongside the actual app storage/networking implementations.
// Success means the secure behavior was verified.
import Foundation

@main struct NativeSecurityRegression {
    static func main() async throws {
        let fm = FileManager.default
        let sandbox = fm.temporaryDirectory.appending(path: "keihatsu-security-\(UUID())")
        let docs = sandbox.appending(path: "Documents")
        try fm.createDirectory(at: docs.appending(path: "downloads"), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: sandbox) }
        let store = ChapterArchiveStore(documentsRoot: docs, applicationSupportRoot: sandbox.appending(path: "Support"))
        let identity = DownloadIdentity(sourceID: "..", mangaID: "..", chapterID: "victim")
        let target = await store.archiveURL(for: identity)
        let victim = sandbox.appending(path: "victim.cbz")
        precondition(target.standardizedFileURL != victim.standardizedFileURL)
        try Data("test sentinel".utf8).write(to: victim)
        try await store.delete(identity)
        precondition(fm.fileExists(atPath: victim.path))
        print("PASS: crafted identifiers cannot delete outside downloads")
        let outside = sandbox.appending(path: "Outside")
        try fm.createDirectory(at: outside.appending(path: "manga"), withIntermediateDirectories: true)
        let sentinel = outside.appending(path: "manga/chapter.cbz")
        try Data("sentinel".utf8).write(to: sentinel)
        try fm.createSymbolicLink(at: docs.appending(path: "downloads/source"), withDestinationURL: outside)
        do {
            try await store.delete(.init(sourceID: "source", mangaID: "manga", chapterID: "chapter"))
            fatalError("External symlink was followed")
        } catch ChapterArchiveStore.ArchiveError.unsafePath {
            precondition(fm.fileExists(atPath: sentinel.path))
            print("PASS: existing symlink cannot delete outside downloads")
        }
        let valid = await store.archiveURL(for: .init(sourceID: "atsumaru", mangaID: "2VgNt", chapterID: "2VgNt/0S_52R"))
        precondition(valid.path.hasSuffix("downloads/atsumaru/2VgNt/0S_52R.cbz"))
        print("PASS: existing valid chapter paths remain unchanged")
        let recordID = UUID()
        let staging = try await store.stagingDirectory(for: recordID)
        let page = staging.appending(path: "page.png")
        let image = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZQmcAAAAASUVORK5CYII=")!
        try image.write(to: page)
        let download = DownloadIdentity(sourceID: "atsumaru", mangaID: "2VgNt", chapterID: "2VgNt/0S_52R")
        let record = ChapterDownloadRecord(
            id: recordID,
            request: .init(identity: download, ownerID: "guest", extensionName: "Atsumaru", mangaTitle: "Test", chapterName: "Test", chapterNumber: 1, thumbnailURL: nil),
            status: .packaging,
            pages: [.init(index: 0, remoteURL: URL(string: "https://example.test/page.png")!, refererURL: nil, stagedFilename: "page.png", byteCount: Int64(image.count))],
            activePageIndex: nil, activeTaskIdentifier: nil, priority: 0, progress: 1,
            errorMessage: nil, archiveByteCount: 0, createdAt: .now, updatedAt: .now
        )
        _ = try await store.package(record: record)
        let exists = await store.contains(download)
        precondition(exists)
        let chapter = ChapterIdentity(manga: .init(sourceID: download.sourceID, mangaID: download.mangaID), chapterID: download.chapterID)
        let pages = try await store.readerPages(for: chapter)
        let restored = try await store.data(for: pages[0].imageURL)
        precondition(restored == image)
        print("PASS: normal native downloads package and read back unchanged")
        do {
            _ = try APIConfiguration(baseURLString: "http://example.test").origin()
            fatalError("HTTP accepted unexpectedly")
        } catch APIError.invalidBaseURL {
            print("PASS: native API configuration rejects HTTP by default")
        }
        let request = APIRequest<EmptyAPIResponse>(path: ["sources", ".."])
        do {
            _ = try request.urlRequest(configuration: APIConfiguration(baseURLString: "https://example.test"))
            fatalError("Dot segment accepted unexpectedly")
        } catch APIError.invalidPath {
            print("PASS: native API request rejects dot path segments")
        }
    }
}
