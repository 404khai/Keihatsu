import Foundation

nonisolated struct AppServices: Sendable {
    let apiClient: APIClient?
    let catalogue: any CatalogueRepository
    let contentLoader: BundledJSONLoader
    let configuration: APIConfiguration
    let isPreview: Bool

    @MainActor static func live(configuration: APIConfiguration = .application(), session: URLSession = .shared) -> Self {
        let client = APIClient(configuration: configuration, session: session)
        let cache = CatalogueCache(namespace: configuration.baseURLString ?? "unconfigured")
        return Self(apiClient: client, catalogue: LiveCatalogueRepository(client: client, cache: cache), contentLoader: BundledJSONLoader(), configuration: configuration, isPreview: false)
    }

    @MainActor static func preview(bundle: Bundle = .main) -> Self {
        let loader = BundledJSONLoader(bundle: bundle)
        return Self(apiClient: nil, catalogue: FixtureCatalogueRepository(loader: loader), contentLoader: loader, configuration: .application(), isPreview: true)
    }
}
