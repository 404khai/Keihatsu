import CryptoKit
import Foundation

actor CatalogueCache {
    private let directory: URL?
    private var memory: [String: Data] = [:]

    init(namespace: String, directory: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first) {
        self.directory = directory?.appendingPathComponent("Catalogue/" + Self.digest(namespace), isDirectory: true)
    }

    func read<Value: Decodable & Sendable>(_ key: String, as: Value.Type) -> Value? {
        let data = memory[key] ?? directory.flatMap { try? Data(contentsOf: $0.appendingPathComponent(Self.digest(key))) }
        guard let data else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func write<Value: Encodable & Sendable>(_ value: Value, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        if memory.count >= 64 { memory.removeAll() }
        memory[key] = data
        guard let directory else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(Self.digest(key)), options: .atomic)
            // Cache storage is disposable and bounded; never evict user reading state here.
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
            if files.count > 100 {
                let oldest = files.sorted { ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) < ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
                for file in oldest.prefix(files.count - 100) { try? FileManager.default.removeItem(at: file) }
            }
        } catch { /* A disposable cache failure must not discard a successful API response. */ }
    }

    nonisolated private static func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
