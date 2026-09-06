import Foundation

nonisolated struct AccountLibraryRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var serverID: String?
    var manga: Manga
    var categoryIDs: Set<UUID>
    var downloadedCount: Int
    var unreadCount: Int
    var totalChapters: Int
    var isStarted: Bool
    var isBookmarked: Bool
    var isCompleted: Bool
    var lastReadAt: Date?
    var lastUpdatedAt: Date
    var dateAddedAt: Date

    var libraryEntry: LibraryEntry {
        LibraryEntry(
            item: ImageModel(manga: manga), categoryIDs: categoryIDs,
            downloadedCount: downloadedCount, unreadCount: unreadCount,
            totalChapters: totalChapters, isStarted: isStarted,
            isBookmarked: isBookmarked, isCompleted: isCompleted,
            lastReadAt: lastReadAt, lastUpdatedAt: lastUpdatedAt, dateAddedAt: dateAddedAt
        )
    }
}

nonisolated struct AccountCategoryRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var serverID: String?
    var name: String
    var libraryCategory: LibraryCategory { LibraryCategory(id: id, name: name) }
}

nonisolated struct AccountCollectionData: Codable, Equatable, Sendable {
    var ownerUserID: String
    var library: [AccountLibraryRecord]
    var categories: [AccountCategoryRecord]

    var snapshot: CollectionSnapshot {
        CollectionSnapshot(library: library.map(\.libraryEntry), categories: categories.map(\.libraryCategory), history: [])
    }
}

nonisolated enum AccountMutation: Codable, Equatable, Sendable {
    case addLibrary(localID: UUID, manga: Manga, categoryIDs: Set<UUID>)
    case removeLibrary(localID: UUID, serverID: String?)
    case updateLibrary(localID: UUID, isUnread: Bool, isStarted: Bool, isBookmarked: Bool, isCompleted: Bool)
    case createCategory(localID: UUID, name: String)
    case renameCategory(localID: UUID, name: String)
    case deleteCategory(localID: UUID, serverID: String?)
    case setCategories(libraryLocalID: UUID, categoryLocalIDs: Set<UUID>)
    case syncHistory(operationID: UUID, progress: ReaderProgressRecord, readingTimeDeltaMilliseconds: Int)
    case deleteHistory(operationID: UUID, manga: MangaIdentity, deletedAt: Date)
    case updatePreferences(SyncedUserPreferences)
}

nonisolated enum AccountMutationState: String, Codable, Equatable, Sendable {
    case queued, syncing, retryableFailure, conflict, authenticationRequired, terminalFailure
}

nonisolated struct AccountOutboxRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let ownerUserID: String
    let mutation: AccountMutation
    var state: AccountMutationState
    var attemptCount: Int
    var createdAt: Date
    var lastError: String?
}
