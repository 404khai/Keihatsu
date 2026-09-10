import CryptoKit
import Foundation

actor AccountCache {
    private let fileURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(namespace: String, directory: URL? = nil, persistToDisk: Bool = true) {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard persistToDisk else { fileURL = nil; return }
        let root = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let digest = SHA256.hash(data: Data(namespace.utf8)).map { String(format: "%02x", $0) }.joined()
        fileURL = root?.appending(path: "Keihatsu/Accounts/\(digest)", directoryHint: .isDirectory)
            .appending(path: "current-account.json")
    }

    func read() -> UserAccount? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(UserAccount.self, from: data)
    }

    func save(_ account: UserAccount) throws {
        guard let fileURL else { return }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(account).write(to: fileURL, options: .atomic)
    }

    func clear() throws {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
