import Foundation

protocol ReaderRepository: Sendable {
    nonisolated func pages(for chapter: Chapter, manga: Manga) async throws -> [ReaderPage]
}

protocol HistoryRepository: Sendable {
    nonisolated func progress(for chapter: ChapterIdentity) async -> ReaderProgressRecord?
    nonisolated func recentProgress() async -> [ReaderProgressRecord]
    nonisolated func saveProgress(_ progress: ReaderProgressRecord) async throws
    nonisolated func toggleBookmark(manga: Manga, chapter: Chapter) async throws -> Bool
}
