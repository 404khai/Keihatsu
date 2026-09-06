import Foundation

/// Composes the existing catalogue boundary; source and manga endpoint construction stays in Data/API.
actor LiveCatalogueRepository: CatalogueRepository {
    private let client: APIClient
    private let cache: CatalogueCache

    init(client: APIClient, cache: CatalogueCache) { self.client = client; self.cache = cache }

    func sources() async throws -> [Source] {
        // Deliberately public: an authenticated response would hide disabled sources.
        let result = try await client.send(SourcesAPI.sources).map { $0.domain() }
        await cache.write(result, key: "sources")
        return result
    }

    func cachedSources() async -> [Source]? { await cache.read("sources", as: [Source].self) }

    func mangas(sourceID: String, listing: CatalogueListing, page: Int, query: String?) async throws -> MangaPage {
        guard page > 0 else { throw APIError.invalidPath }
        let result = try await client.send(SourcesAPI.listing(sourceID: sourceID, type: listing, page: page, query: query)).domain()
        guard result.mangas.allSatisfy({ $0.id.sourceID == sourceID }) else { throw APIError.decoding }
        await cache.write(result, key: key(sourceID, listing, page, query))
        return result
    }

    func cachedMangas(sourceID: String, listing: CatalogueListing, page: Int, query: String?) async -> MangaPage? {
        await cache.read(key(sourceID, listing, page, query), as: MangaPage.self)
    }

    func manga(_ id: MangaIdentity) async throws -> Manga {
        try await client.send(APIRequest<MangaDTO>(path: ["sources", id.sourceID, "manga", id.mangaID])).domain()
    }

    func chapters(for manga: MangaIdentity) async throws -> [Chapter] {
        try await client.send(APIRequest<[ChapterDTO]>(path: ["sources", manga.sourceID, "manga", manga.mangaID, "chapters"])).map { $0.domain(manga: manga) }
    }

    func pages(for chapter: ChapterIdentity) async throws -> [ReaderPage] {
        try await client.send(APIRequest<[ReaderPageDTO]>(path: ["sources", chapter.manga.sourceID, "chapters", chapter.chapterID, "pages"])).map { try $0.domain(chapter: chapter) }
    }

    private func key(_ source: String, _ listing: CatalogueListing, _ page: Int, _ query: String?) -> String {
        // JSON avoids ambiguous separators inside opaque source/query values.
        String(data: (try? JSONEncoder().encode([source, listing.rawValue, String(page), query ?? ""])) ?? Data(), encoding: .utf8) ?? ""
    }
}
