import Foundation

/// Explicit preview/test dependency. Never a fallback for a failed live request.
actor FixtureCatalogueRepository: CatalogueRepository {
    private let loader: BundledJSONLoader

    init(loader: BundledJSONLoader = BundledJSONLoader()) { self.loader = loader }

    func sources() async throws -> [Source] {
        try loader.load("catalogue-sources", as: [SourceDTO].self).map { $0.domain() }
    }

    func mangas(sourceID: String, listing: CatalogueListing, page: Int, query: String?) async throws -> MangaPage {
        let response = try loader.load("catalogue-manga", as: MangaPageDTO.self)
        let matches = response.mangas.filter {
            $0.sourceId == sourceID && (listing != .search || query?.isEmpty != false || $0.title.localizedCaseInsensitiveContains(query ?? ""))
        }
        return MangaPage(mangas: page == 1 ? matches.map { $0.domain() } : [], hasNextPage: false)
    }

    func manga(_ id: MangaIdentity) async throws -> Manga {
        let response = try loader.load("catalogue-manga", as: MangaPageDTO.self)
        guard let manga = response.mangas.first(where: { $0.sourceId == id.sourceID && $0.id == id.mangaID }) else {
            throw APIError.http(status: 404, message: "This title is not in the preview catalogue.")
        }
        return manga.domain()
    }

    func chapters(for id: MangaIdentity) async throws -> [Chapter] {
        _ = try await manga(id)
        return try loader.load("catalogue-chapters", as: [ChapterDTO].self).map { $0.domain(manga: id) }
    }

    func pages(for chapter: ChapterIdentity) async throws -> [ReaderPage] {
        let chapters = try await chapters(for: chapter.manga)
        guard chapters.contains(where: { $0.id == chapter }) else { throw APIError.http(status: 404, message: nil) }
        return try loader.load("catalogue-pages", as: [ReaderPageDTO].self).map { try $0.domain(chapter: chapter) }
    }
}
