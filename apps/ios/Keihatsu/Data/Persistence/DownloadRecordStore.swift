import CryptoKit
import Foundation

actor DownloadRecordStore {
    private let fileURL: URL?
    private var memory: [ChapterDownloadRecord] = []

    init(namespace: String, root: URL? = nil, persistToDisk: Bool = true) {
        guard persistToDisk else {
            fileURL = nil
            return
        }
        let digest = SHA256.hash(data: Data(namespace.utf8)).map { String(format: "%02x", $0) }.joined()
        let base = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        fileURL = base?
            .appending(path: "Keihatsu/Downloads/\(digest)", directoryHint: .isDirectory)
            .appending(path: "queue.json", directoryHint: .notDirectory)
    }

    func load() -> [ChapterDownloadRecord] {
        guard memory.isEmpty, let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ChapterDownloadRecord].self, from: data) else {
            return memory
        }
        memory = decoded
        return memory
    }

    func save(_ records: [ChapterDownloadRecord]) throws {
        memory = records
        guard let fileURL else { return }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(records)
        let temporary = fileURL.appendingPathExtension("part")
        try data.write(to: temporary, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temporary)
        } else {
            try FileManager.default.moveItem(at: temporary, to: fileURL)
        }
    }
}
