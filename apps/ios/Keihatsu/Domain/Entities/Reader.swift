import Foundation

nonisolated struct ReaderProgressRecord: Identifiable, Codable, Equatable, Sendable {
    var manga: Manga
    var chapter: Chapter
    var pageIndex: Int
    var intraPageAnchor: Double
    var totalPages: Int
    var activeReadingSeconds: Double
    var isRead: Bool
    var isBookmarked: Bool
    var updatedAt: Date

    var id: ChapterIdentity { chapter.id }
    var displayedPage: Int { min(max(pageIndex + 1, 1), max(totalPages, 1)) }
}

nonisolated struct LoadedReaderChapter: Identifiable, Equatable, Sendable {
    let chapter: Chapter
    let pages: [ReaderPage]
    var id: ChapterIdentity { chapter.id }
}

nonisolated enum ReaderSessionEvent: Equatable, Sendable {
    case started(sessionID: UUID, chapter: ChapterIdentity, at: Date)
    case visiblePageChanged(sessionID: UUID, page: ReaderPage.ID, at: Date)
    case suspended(sessionID: UUID, chapter: ChapterIdentity, pageIndex: Int, at: Date)
    case ended(sessionID: UUID, chapter: ChapterIdentity, pageIndex: Int, at: Date)
}
