import Foundation

nonisolated struct ChapterReadingState: Codable, Equatable, Sendable {
    var isRead = false
    var isBookmarked = false
    var isDownloaded = false
    var lastReadAt: Date?
    var pageIndex: Int?
}

nonisolated struct MangaDetailsRecord: Codable, Equatable, Sendable {
    var manga: Manga
    var chapters: [Chapter]
    var chapterStates: [String: ChapterReadingState]
    var updatedAt: Date

    func state(for chapter: ChapterIdentity) -> ChapterReadingState {
        chapterStates[chapter.chapterID] ?? ChapterReadingState()
    }
}

nonisolated struct ChapterFilter: Equatable, Sendable {
    var downloaded = false
    var unread = false
    var bookmarked = false

    func includes(_ chapter: Chapter, state: ChapterReadingState) -> Bool {
        (!downloaded || state.isDownloaded)
            && (!unread || !state.isRead)
            && (!bookmarked || state.isBookmarked)
    }
}

nonisolated struct ResumeChapter: Equatable, Sendable {
    let chapter: Chapter
    let pageIndex: Int?
    let hasHistory: Bool
}
