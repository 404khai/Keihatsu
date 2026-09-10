import Foundation
import SwiftUI
import Testing
@testable import Keihatsu

@Suite @MainActor
struct FoundationTests {
    @Test func bootstrapPersistsGuestEntryWithoutResettingPreferences() throws {
        let name = "keihatsu.tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = AppPreferencesStore(userDefaults: defaults)
        preferences.preferences.colorScheme = .dark
        let bootstrap = AppBootstrap(defaults: defaults)
        #expect(bootstrap.stage == .onboarding)
        bootstrap.completeOnboarding()
        #expect(AppBootstrap(defaults: defaults).stage == .accountEntry)
        bootstrap.enterAsGuest()
        #expect(AppBootstrap(defaults: defaults).stage == .mainApp)
        #expect(AppPreferencesStore(userDefaults: defaults).preferences.colorScheme == .dark)
    }

    @Test func tabStacksAreIndependent() {
        let navigation = AppNavigation()
        navigation.homePath.append("home-detail")
        navigation.selectedTab = .library
        navigation.libraryPath.append("library-detail")
        navigation.profilePath.append("profile-detail")
        #expect(navigation.homePath.count == 1)
        #expect(navigation.libraryPath.count == 1)
        #expect(navigation.profilePath.count == 1)
        #expect(navigation.searchPath.isEmpty)
        navigation.reset()
        #expect(navigation.homePath.isEmpty && navigation.libraryPath.isEmpty && navigation.profilePath.isEmpty)
        #expect(navigation.selectedTab == .library)
    }

    @Test func fixtureDecodingPreservesSourceAndChapterIdentity() async throws {
        let repository = FixtureCatalogueRepository()
        let sources = try await repository.sources()
        #expect(sources.first?.id == "manhuatop")
        let page = try await repository.mangas(sourceID: "manhuatop", listing: .search, page: 1, query: "Player")
        let manga = try #require(page.mangas.first)
        #expect(manga.title == "Player")
        #expect(!page.hasNextPage)
        let chapters = try await repository.chapters(for: manga.id)
        #expect(chapters[0].uploadedAt == nil)
        #expect(chapters[1].number == 263.5)
        #expect(chapters[0].id.manga == manga.id)
        let pages = try await repository.pages(for: chapters[0].id)
        #expect(pages[0].id.index == 0)
        #expect(pages[0].id.chapter == chapters[0].id)
        #expect(MangaIdentity(sourceID: "a", mangaID: "same") != MangaIdentity(sourceID: "b", mangaID: "same"))
    }

    @Test func onboardingAssetsAndCopyAreBundled() throws {
        let pages = try BundledJSONLoader().load("onboarding", as: [OnboardingPage].self)
        #expect(pages.count == 3)
        for page in pages { #expect(UIImage(named: page.image) != nil) }
    }

    @Test func liveCompositionDoesNotFallBackToPreviewOrSimulateSync() {
        let services = AppServices.live()
        #expect(services.apiClient != nil)
        #expect(services.catalogue is LiveCatalogueRepository)
        #expect(AppServices.preview().apiClient == nil)
        let sync = SyncQueueStore()
        #expect(sync.operations.isEmpty)
        #expect(sync.lastSyncedAt == nil)
    }

    @Test func requestEncodesOpaqueIDsAndRequiresExplicitAuthentication() throws {
        let configuration = APIConfiguration(baseURLString: "https://api.example.test")
        let id = "https://source.test/manga/a%2Fb?q=é#x"
        let endpoint = APIRequest<EmptyAPIResponse>(path: ["sources", "manhuatop", "manga", id])
        let request = try endpoint.urlRequest(configuration: configuration, bearerToken: "unused")
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.percentEncodedPath.split(separator: "/").count == 4)
        #expect(components.percentEncodedPath.split(separator: "/").last?.removingPercentEncoding == id)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        let secured = APIRequest<EmptyAPIResponse>(path: ["auth", "me"], requiresAuthentication: true)
        #expect(throws: APIError.authenticationRequired) { try secured.urlRequest(configuration: configuration) }
        #expect(try secured.urlRequest(configuration: configuration, bearerToken: "test").value(forHTTPHeaderField: "Authorization") == "Bearer test")
    }

    @Test func missingAndInsecureConfigurationFailExplicitly() throws {
        #expect(throws: APIError.missingConfiguration) { try APIConfiguration(baseURLString: "").origin() }
        #expect(throws: APIError.invalidBaseURL) { try APIConfiguration(baseURLString: "http://api.example.test").origin() }
        #expect(throws: APIError.invalidBaseURL) { try APIConfiguration(baseURLString: "https://user:secret@api.example.test").origin() }
        #expect(try APIConfiguration(baseURLString: "http://127.0.0.1:3000", allowsInsecureHTTP: true).origin().port == 3000)
    }
}
