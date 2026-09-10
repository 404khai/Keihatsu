import Foundation

protocol MangaDetailsRepository: Sendable {
    nonisolated func cachedRecord(for id: MangaIdentity) async -> MangaDetailsRecord?
    nonisolated func refreshMetadata(for id: MangaIdentity) async throws -> Manga
    nonisolated func refreshChapters(for id: MangaIdentity) async throws -> [Chapter]
    nonisolated func recommendations(for id: MangaIdentity) async throws -> [Manga]
    nonisolated func updateState(
        for chapter: ChapterIdentity,
        _ update: @Sendable (inout ChapterReadingState) -> Void
    ) async throws -> MangaDetailsRecord
}
