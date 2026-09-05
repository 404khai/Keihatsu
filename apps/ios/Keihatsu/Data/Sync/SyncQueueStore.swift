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
        operations: [SyncOperation] = [
            SyncOperation(kind: .library, summary: "Refresh saved titles from local library"),
            SyncOperation(kind: .history, summary: "Upload recent reading progress"),
            SyncOperation(kind: .preferences, summary: "Sync app and reader preferences")
        ],
        lastSyncedAt: Date? = nil
    ) {
        self.operations = operations
        self.lastSyncedAt = lastSyncedAt
    }

    func enqueue(_ operation: SyncOperation) {
        operations.insert(operation, at: 0)
    }

    func markAllCompleted() {
        operations = operations.map { operation in
            var updated = operation
            updated.status = .completed
            return updated
        }
        lastSyncedAt = .now
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
}
