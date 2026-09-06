import Foundation

nonisolated struct LibraryEntry: Identifiable, Codable, Sendable {
    let item: ImageModel
    var categoryIDs: Set<UUID>
    let downloadedCount: Int
    let unreadCount: Int
    let totalChapters: Int
    let isStarted: Bool
    let isBookmarked: Bool
    let isCompleted: Bool
    let lastReadAt: Date?
    let lastUpdatedAt: Date
    let dateAddedAt: Date
    var id: UUID { item.id }
}

nonisolated struct LibraryCategory: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
}

nonisolated struct HistoryItem: Identifiable, Codable, Sendable {
    let id: UUID
    let image: String
    let title: String
    let chapter: String
    let readAt: Date
    var time: String { readAt.formatted(date: .omitted, time: .shortened) }
}

nonisolated struct HistorySection: Identifiable {
    let id: Date
    let date: String
    let items: [HistoryItem]
}

nonisolated struct CollectionSnapshot: Codable, Sendable {
    var library: [LibraryEntry]
    var categories: [LibraryCategory]
    var history: [HistoryItem]
}
