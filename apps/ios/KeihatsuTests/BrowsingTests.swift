import Foundation
import Testing
@testable import Keihatsu

@Suite @MainActor
struct BrowsingTests {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "keihatsu.tests.\(UUID())")! }
    private func source(_ id: String) -> Source { Source(id: id, name: id, language: "en", baseURL: URL(string: "https://example.test"), iconURL: nil, version: 1) }
    private func manga(_ id: String, source: String = "manhuatop") -> Manga {
        Manga(id: .init(sourceID: source, mangaID: id), title: id, url: nil, thumbnailURL: nil, description: nil, author: nil, artist: nil, status: nil, genres: [], language: nil)
    }

    @Test func sourceGateAndPreferencesSurviveRefreshAndRelaunch() async {
        let repository = BrowsingRepositoryStub(sources: [source("manhuatop"), source("batcave")])
        let preferences = defaults()
        let store = SourcePreferencesStore(repository: repository, defaults: preferences)
        await store.load()
        #expect(store.sources.count == 2)
        #expect(store.enabledSources.map(\.id) == ["manhuatop"])
        store.setEnabled(true, source: source("batcave"))
        #expect(!store.isEnabled(source("batcave")))
        store.setEnabled(false, source: source("manhuatop"))
        store.setPinned(false, source: source("manhuatop"))
        await store.load(force: true)
        #expect(store.enabledSources.isEmpty)
        let restored = SourcePreferencesStore(repository: repository, defaults: preferences)
        await restored.load()
        #expect(restored.enabledSources.isEmpty)
        #expect(!restored.isPinned(source("manhuatop")))
    }

    @Test func homeDeduplicatesIsolatesFailuresAndBoundsConcurrency() async {
        let sources = (1...5).map { source("source\($0)") }
        let repository = BrowsingRepositoryStub(sources: sources)
        for source in sources {
            await repository.set(source.id, page: MangaPage(mangas: [manga("same", source: source.id), manga("same", source: source.id)], hasNextPage: false))
        }
        let model = HomeViewModel(repository: repository)
        await model.load(sources: sources)
        #expect(model.mangas.count == 5)
        #expect(await repository.maximumActive <= 3)
        await repository.fail("source1")
        await model.load(sources: sources)
        #expect(model.sections.first?.error != nil)
        #expect(model.sections.first?.isCached == true)
        #expect(model.mangas.count == 5)
        #expect(model.sections.dropFirst().allSatisfy { $0.error == nil })
        await model.load(sources: [])
        #expect(model.mangas.isEmpty && !model.isLoading)
    }

    @Test func staleSearchCannotReplaceNewQueryAndPaginationStops() async throws {
        let repository = BrowsingRepositoryStub(sources: [source("manhuatop")])
        await repository.set("manhuatop:old:1", page: MangaPage(mangas: [manga("old")], hasNextPage: false), delay: 150)
        await repository.set("manhuatop:new:1", page: MangaPage(mangas: [manga("new")], hasNextPage: true))
        await repository.set("manhuatop:new:2", page: MangaPage(mangas: [manga("new"), manga("second")], hasNextPage: false))
        let model = SearchViewModel(repository: repository, defaults: defaults())
        let old = Task { await model.search("old", sources: [source("manhuatop")], debounce: false) }
        try await Task.sleep(for: .milliseconds(20))
        await model.search("new", sources: [source("manhuatop")], debounce: false)
        await old.value
        #expect(model.sections.first?.mangas.map(\.title) == ["new"])
        await model.loadMore("manhuatop")
        #expect(model.sections.first?.mangas.map(\.title) == ["new", "second"])
        let count = await repository.count
        await model.loadMore("manhuatop")
        #expect(await repository.count == count)
        await model.search("", sources: [source("manhuatop")], debounce: false)
        #expect(model.sections.isEmpty)
    }

    @Test func failedPaginationRetriesSamePageWithoutDroppingResults() async {
        let repository = BrowsingRepositoryStub(sources: [source("manhuatop")])
        await repository.set("manhuatop:q:1", page: MangaPage(mangas: [manga("first")], hasNextPage: true))
        await repository.fail("manhuatop:q:2")
        let model = SearchViewModel(repository: repository, defaults: defaults())
        await model.search("q", sources: [source("manhuatop")], debounce: false)
        await model.loadMore("manhuatop")
        #expect(model.sections.first?.mangas.count == 1)
        #expect(model.sections.first?.error != nil)
        #expect(model.sections.first?.page == 1)
        await repository.set("manhuatop:q:2", page: MangaPage(mangas: [manga("second")], hasNextPage: false))
        await model.retry("manhuatop")
        #expect(model.sections.first?.page == 2)
        #expect(model.sections.first?.mangas.count == 2)
    }

    @Test func recentQueriesAreBoundedDeduplicatedAndPersisted() {
        let preferences = defaults()
        let repository = BrowsingRepositoryStub(sources: [])
        let model = SearchViewModel(repository: repository, defaults: preferences)
        for index in 0...6 { model.remember("query\(index)") }
        model.remember(" QUERY3 ")
        #expect(model.recentQueries.count == 5)
        #expect(model.recentQueries.first == "QUERY3")
        let restored = SearchViewModel(repository: repository, defaults: preferences)
        #expect(restored.recentQueries == model.recentQueries)
        restored.clearHistory()
        #expect(preferences.stringArray(forKey: "keihatsu.search.recent") == nil)
    }

    @Test func collectionFiltersSortsCategoriesAndHistoryUseRepositoryState() throws {
        let store = CollectionStore(repository: FixtureCollectionRepository())
        #expect(store.error == nil)
        #expect(store.snapshot.library.count == 12)
        var options = LibraryOptions()
        options.sort = .alphabetical
        options.ascending = true
        let entries = options.filtered(store.snapshot.library, category: nil, query: "")
        #expect(entries.count == 7)
        #expect(entries.map { $0.item.title } == entries.map { $0.item.title }.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        for filter in [\LibraryOptions.downloaded, \.unread, \.started, \.bookmarked, \.completed] {
            var selected = options
            selected[keyPath: filter] = true
            let result = selected.filtered(store.snapshot.library, category: nil, query: "")
            #expect(!result.isEmpty && result.count < entries.count)
        }
        options.downloaded = true; options.unread = true
        #expect(options.filtered(store.snapshot.library, category: nil, query: "").allSatisfy { $0.downloadedCount > 0 && $0.unreadCount > 0 })
        #expect(store.saveCategory(id: nil, name: "Favorites"))
        #expect(!store.saveCategory(id: nil, name: "favorites"))
        let category = try #require(store.snapshot.categories.last)
        let entry = try #require(store.snapshot.library.first)
        store.assign(category.id, entry: entry.id, included: true)
        #expect(store.snapshot.library.first?.categoryIDs.contains(category.id) == true)
        #expect(store.saveCategory(id: category.id, name: "Favorites renamed"))
        store.deleteCategory(category.id)
        #expect(store.snapshot.library.first?.categoryIDs.isEmpty == true)
        let history = try #require(store.snapshot.history.first)
        store.deleteHistory([history.id])
        #expect(store.snapshot.history.count == 11)
        #expect(!store.historySections(query: "").flatMap(\.items).contains { $0.id == history.id })
        let defaults = defaults()
        let display = LibraryOptionsStore(defaults: defaults)
        for layout in LibraryLayout.allCases {
            display.options.layout = layout
            #expect(LibraryOptionsStore(defaults: defaults).options.layout == layout)
        }
    }

    @Test func listingAdapterKeepsStableNavigationIdentity() {
        let first = ImageModel(manga: manga("opaque/id?foo=bar"))
        for _ in 0..<20 { #expect(ImageModel(manga: manga("opaque/id?foo=bar")).id == first.id) }
        #expect(ImageModel(manga: manga("opaque/id?foo=bar", source: "other")).id != first.id)
    }

    @Test func imageProxyIsRestrictedAndNeverAddsAuthentication() throws {
        let configuration = APIConfiguration(baseURLString: "https://api.example.test")
        let image = URL(string: "https://manhuatop.org/cover.webp?q=a&b=2")!
        let proxy = try ImagePipeline.request(url: image, referer: URL(string: "https://manhuatop.org/manga/a"), configuration: configuration)
        #expect(proxy.url?.host == "api.example.test")
        #expect(URLComponents(url: proxy.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value == image.absoluteString)
        #expect(proxy.value(forHTTPHeaderField: "Authorization") == nil)
        let direct = try ImagePipeline.request(url: URL(string: "https://cdn.example.test/cover.jpg")!, referer: nil, configuration: configuration)
        #expect(direct.url?.host == "cdn.example.test")
        #expect(throws: APIError.invalidBaseURL) { try ImagePipeline.request(url: URL(string: "http://cdn.example.test/x")!, referer: nil, configuration: configuration) }
    }
}

private actor BrowsingRepositoryStub: CatalogueRepository {
    let sourceList: [Source]
    var pages: [String: MangaPage] = [:]
    var failures = Set<String>()
    var delays: [String: Int] = [:]
    var count = 0
    var active = 0
    var maximumActive = 0
    init(sources: [Source]) { sourceList = sources }
    func set(_ key: String, page: MangaPage, delay: Int = 10) { pages[key] = page; delays[key] = delay; failures.remove(key) }
    func fail(_ key: String) { failures.insert(key) }
    func sources() async throws -> [Source] { sourceList }
    func mangas(sourceID: String, listing: CatalogueListing, page: Int, query: String?) async throws -> MangaPage {
        let key = listing == .search ? "\(sourceID):\(query ?? ""):\(page)" : sourceID
        count += 1; active += 1; maximumActive = max(active, maximumActive)
        defer { active -= 1 }
        // Intentionally ignore cancellation to verify generation checks against uncooperative work.
        try? await Task.sleep(for: .milliseconds(delays[key] ?? 10))
        if failures.contains(key) { throw APIError.http(status: 503, message: "Provider unavailable") }
        return pages[key] ?? MangaPage(mangas: [], hasNextPage: false)
    }
    func manga(_ id: MangaIdentity) async throws -> Manga { throw APIError.invalidResponse }
    func chapters(for manga: MangaIdentity) async throws -> [Chapter] { [] }
    func pages(for chapter: ChapterIdentity) async throws -> [ReaderPage] { [] }
}
