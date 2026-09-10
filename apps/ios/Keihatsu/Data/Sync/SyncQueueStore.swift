import Combine
import Foundation

@MainActor
final class SyncQueueStore: ObservableObject {
    @Published private(set) var operations: [SyncOperation]
    @Published private(set) var lastSyncedAt: Date?

    var pendingCount: Int {
        operations.filter { $0.status == .queued || $0.status == .failed }.count
    }

    init(
        operations: [SyncOperation] = [],
        lastSyncedAt: Date? = nil
    ) {
        self.operations = operations
        self.lastSyncedAt = lastSyncedAt
    }

    func enqueue(_ operation: SyncOperation) {
        operations.insert(operation, at: 0)
    }

    func retryFailed() {
        operations = operations.map { operation in
            var updated = operation
            if updated.status == .failed {
                updated.status = .queued
            }
            return updated
        }
    }

    func replace(with operations: [SyncOperation], lastSyncedAt: Date?) {
        self.operations = operations
        self.lastSyncedAt = lastSyncedAt
    }

    func markSynced() { lastSyncedAt = .now }

    func setError(_ message: String) {
        operations.insert(SyncOperation(kind: .preferences, summary: message, status: .failed), at: 0)
    }
}
