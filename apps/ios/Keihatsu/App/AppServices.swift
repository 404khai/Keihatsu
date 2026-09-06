import Foundation

nonisolated struct AppServices: Sendable {
    let apiClient: APIClient?
    let catalogue: any CatalogueRepository
    let mangaDetails: any MangaDetailsRepository
    let contentLoader: BundledJSONLoader
    let configuration: APIConfiguration
    let isPreview: Bool

    @MainActor static func live(configuration: APIConfiguration = .application(), session: URLSession = .shared) -> Self {
        let client = APIClient(configuration: configuration, session: session)
        let cache = CatalogueCache(namespace: configuration.baseURLString ?? "unconfigured")
        let catalogue = LiveCatalogueRepository(client: client, cache: cache)
        let detailsStore = MangaDetailsStore(namespace: configuration.baseURLString ?? "unconfigured")
        return Self(apiClient: client, catalogue: catalogue, mangaDetails: DefaultMangaDetailsRepository(catalogue: catalogue, store: detailsStore), contentLoader: BundledJSONLoader(), configuration: configuration, isPreview: false)
    }

    @MainActor static func preview(bundle: Bundle = .main) -> Self {
        let loader = BundledJSONLoader(bundle: bundle)
        let catalogue = FixtureCatalogueRepository(loader: loader)
        let detailsStore = MangaDetailsStore(namespace: "preview", persistToDisk: false)
        return Self(apiClient: nil, catalogue: catalogue, mangaDetails: DefaultMangaDetailsRepository(catalogue: catalogue, store: detailsStore), contentLoader: loader, configuration: .application(), isPreview: true)
    }
}
