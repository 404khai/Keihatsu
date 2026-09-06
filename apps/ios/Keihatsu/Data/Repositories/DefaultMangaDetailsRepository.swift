import Foundation

actor DefaultMangaDetailsRepository: MangaDetailsRepository {
    private let catalogue: any CatalogueRepository
    private let store: MangaDetailsStore

    init(catalogue: any CatalogueRepository, store: MangaDetailsStore) {
        self.catalogue = catalogue
        self.store = store
    }

    func cachedRecord(for id: MangaIdentity) async -> MangaDetailsRecord? {
        await store.record(for: id)
    }

    func refreshMetadata(for id: MangaIdentity) async throws -> Manga {
        let manga = try await catalogue.manga(id)
        _ = try await store.mergeMetadata(manga)
        return manga
    }

    func refreshChapters(for id: MangaIdentity) async throws -> [Chapter] {
        let chapters = ChapterOrdering.newestFirst(try await catalogue.chapters(for: id))
        _ = try await store.mergeChapters(chapters, for: id)
        return chapters
    }

    func recommendations(for id: MangaIdentity) async throws -> [Manga] {
        let page = try await catalogue.mangas(sourceID: id.sourceID, listing: .popular, page: 1, query: nil)
        var seen = Set<MangaIdentity>()
        return page.mangas.filter { $0.id != id && seen.insert($0.id).inserted }.prefix(12).map { $0 }
    }

    func updateState(
        for chapter: ChapterIdentity,
        _ update: @Sendable (inout ChapterReadingState) -> Void
    ) async throws -> MangaDetailsRecord {
        try await store.updateState(for: chapter, update)
    }
}
