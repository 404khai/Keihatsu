import Foundation

nonisolated struct AppServices: Sendable {
    let apiClient: APIClient?
    /// Live feature repositories are supplied in Phase 2; no preview fallback is installed.
    let catalogue: (any CatalogueRepository)?
    let contentLoader: BundledJSONLoader

    static func live(configuration: APIConfiguration = .application(), session: URLSession = .shared) -> Self {
        Self(apiClient: APIClient(configuration: configuration, session: session), catalogue: nil, contentLoader: BundledJSONLoader())
    }

    @MainActor static func preview(bundle: Bundle = .main) -> Self {
        let loader = BundledJSONLoader(bundle: bundle)
        return Self(apiClient: nil, catalogue: FixtureCatalogueRepository(loader: loader), contentLoader: loader)
    }
}
