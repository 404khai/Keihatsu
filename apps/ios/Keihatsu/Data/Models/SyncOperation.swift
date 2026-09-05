import Foundation

struct SyncOperation: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: SyncOperationKind
    var summary: String
    var status: SyncOperationStatus
    var queuedAt: Date

    init(
        id: UUID = UUID(),
        kind: SyncOperationKind,
        summary: String,
        status: SyncOperationStatus = .queued,
        queuedAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.summary = summary
        self.status = status
        self.queuedAt = queuedAt
    }
}

enum SyncOperationKind: String, Codable, CaseIterable {
    case library
    case history
    case bookmarks
    case preferences

    var label: String {
        switch self {
        case .library: return "Library"
        case .history: return "History"
        case .bookmarks: return "Bookmarks"
        case .preferences: return "Preferences"
        }
    }
}

enum SyncOperationStatus: String, Codable {
    case queued
    case syncing
    case failed
    case completed

    var label: String {
        switch self {
        case .queued: return "Queued"
        case .syncing: return "Syncing"
        case .failed: return "Failed"
        case .completed: return "Completed"
        }
    }
}
