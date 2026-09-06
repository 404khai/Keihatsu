import Foundation

nonisolated enum CatalogueListing: String, Sendable {
    case popular, latest, search
}

protocol CatalogueRepository: Sendable {
    nonisolated func sources() async throws -> [Source]
    nonisolated func mangas(sourceID: String, listing: CatalogueListing, page: Int, query: String?) async throws -> MangaPage
    nonisolated func manga(_ id: MangaIdentity) async throws -> Manga
    nonisolated func chapters(for manga: MangaIdentity) async throws -> [Chapter]
    nonisolated func pages(for chapter: ChapterIdentity) async throws -> [ReaderPage]
}
