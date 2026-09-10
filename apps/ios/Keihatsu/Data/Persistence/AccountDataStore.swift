import CryptoKit
import Foundation

actor AccountDataStore {
    private struct State: Codable {
        var collections: [String: AccountCollectionData] = [:]
        var outbox: [AccountOutboxRecord] = []
    }

    private let fileURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var state = State()
    private var loaded = false

    init(namespace: String, directory: URL? = nil, persistToDisk: Bool = true) {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard persistToDisk else { fileURL = nil; return }
        let root = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let digest = SHA256.hash(data: Data(namespace.utf8)).map { String(format: "%02x", $0) }.joined()
        fileURL = root?.appending(path: "Keihatsu/Accounts/\(digest)", directoryHint: .isDirectory)
            .appending(path: "account-data.json")
    }

    func collections(ownerUserID: String) -> AccountCollectionData? {
        loadIfNeeded()
        return state.collections[ownerUserID]
    }

    func save(_ value: AccountCollectionData) throws {
        loadIfNeeded()
        state.collections[value.ownerUserID] = value
        try persist()
    }

    func outbox(ownerUserID: String) -> [AccountOutboxRecord] {
        loadIfNeeded()
        return state.outbox.filter { $0.ownerUserID == ownerUserID }.sorted { $0.createdAt < $1.createdAt }
    }

    func enqueue(ownerUserID: String, mutation: AccountMutation) throws {
        loadIfNeeded()
        state.outbox.append(AccountOutboxRecord(
            id: UUID(), ownerUserID: ownerUserID, mutation: mutation,
            state: .queued, attemptCount: 0, createdAt: .now, lastError: nil
        ))
        try persist()
    }

    func updateOutbox(id: UUID, state newState: AccountMutationState, error: String? = nil) throws {
        loadIfNeeded()
        guard let index = state.outbox.firstIndex(where: { $0.id == id }) else { return }
        state.outbox[index].state = newState
        state.outbox[index].lastError = error
        if newState != .syncing { state.outbox[index].attemptCount += 1 }
        try persist()
    }

    func acknowledgeOutbox(id: UUID) throws {
        loadIfNeeded()
        state.outbox.removeAll { $0.id == id }
        try persist()
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let fileURL, let data = try? Data(contentsOf: fileURL), let restored = try? decoder.decode(State.self, from: data) else { return }
        state = restored
    }

    private func persist() throws {
        guard let fileURL else { return }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(state).write(to: fileURL, options: .atomic)
    }
}
