import Combine
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    let collections: CollectionStore
    let libraryOptions: LibraryOptionsStore
    let sources: SourcePreferencesStore
    let home: HomeViewModel
    let search: SearchViewModel
    let imagePipeline: ImagePipeline
    let readingHistory: ReadingHistoryModel
    let services: AppServices
    let navigation: AppNavigation
    let bootstrap: AppBootstrap
    let preferencesStore: AppPreferencesStore
    let syncQueueStore: SyncQueueStore
    let accountData: AccountDataCoordinator
    let accountSession: AccountSessionStore
    let commentsAPI: any CommentsServicing
    let downloads: DownloadCoordinator
    let liveActivities: LiveActivityCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(services: AppServices? = nil, defaults: UserDefaults = .standard) {
        let services = services ?? .live()
        self.services = services
        let collections = CollectionStore(repository: FixtureCollectionRepository(loader: services.contentLoader))
        let libraryOptions = LibraryOptionsStore(defaults: defaults)
        let sources = SourcePreferencesStore(repository: services.catalogue, defaults: defaults)
        self.collections = collections
        self.libraryOptions = libraryOptions
        self.sources = sources
        home = HomeViewModel(repository: services.catalogue)
        search = SearchViewModel(repository: services.catalogue, defaults: defaults)
        imagePipeline = ImagePipeline(configuration: services.configuration, archiveStore: services.archiveStore)
        let readingHistory = ReadingHistoryModel(repository: services.history)
        self.readingHistory = readingHistory
        navigation = AppNavigation()
        bootstrap = AppBootstrap(defaults: defaults)
        preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let liveActivities = LiveActivityCoordinator(isAvailable: !services.isPreview)
        self.liveActivities = liveActivities
        let syncQueueStore = SyncQueueStore()
        self.syncQueueStore = syncQueueStore

        let accountClient = services.apiClient ?? APIClient(configuration: APIConfiguration(baseURLString: "https://preview.invalid"))
        let userAPI = UserAPI(client: accountClient)
        let accountData = AccountDataCoordinator(
            libraryAPI: LibraryAPI(client: accountClient),
            categoriesAPI: CategoriesAPI(client: accountClient),
            historyAPI: HistoryAPI(client: accountClient),
            userAPI: userAPI,
            store: AccountDataStore(
                namespace: services.configuration.baseURLString ?? "unconfigured",
                persistToDisk: !services.isPreview
            ),
            collections: collections,
            historyRepository: services.history,
            readingHistory: readingHistory,
            libraryOptions: libraryOptions,
            sources: sources,
            syncStatus: syncQueueStore
        )
        self.accountData = accountData
        let google: any GoogleIdentityProviding = services.isPreview ? UnavailableGoogleIdentityProvider() : GoogleIdentityProvider()
        accountSession = AccountSessionStore(
            authentication: AuthAPI(client: accountClient),
            users: userAPI,
            google: google,
            credentials: KeychainTokenStore(service: "\(Bundle.main.bundleIdentifier ?? "com.keihatsu.ios").account"),
            cache: AccountCache(
                namespace: services.configuration.baseURLString ?? "unconfigured",
                persistToDisk: !services.isPreview
            ),
            accountData: accountData
        )
        commentsAPI = CommentsAPI(client: accountClient)
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        downloads = DownloadCoordinator(
            catalogue: services.catalogue,
            archiveStore: services.archiveStore,
            recordStore: DownloadRecordStore(
                namespace: services.configuration.baseURLString ?? "unconfigured",
                persistToDisk: !services.isPreview
            ),
            transfer: BackgroundDownloadSession(
                identifier: "\(Bundle.main.bundleIdentifier ?? "com.keihatsu.ios").chapter-downloads",
                incomingRoot: support.appending(path: "Keihatsu/DownloadIncoming", directoryHint: .isDirectory),
                usesBackgroundConfiguration: !services.isPreview
            ),
            configuration: services.configuration,
            network: DownloadNetworkMonitor(),
            preferences: preferencesStore,
            defaults: defaults
        )
        collections.mutationHandler = accountData
        readingHistory.syncCoordinator = accountData

        Publishers.CombineLatest(libraryOptions.$options, sources.$revision)
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak accountData, weak libraryOptions, weak sources] _, _ in
                guard let accountData, let libraryOptions, let sources else { return }
                var value = libraryOptions.syncedPreferences
                value.sourcePreferences = sources.syncedPreferences
                accountData.queuePreferences(value)
            }
            .store(in: &cancellables)

        accountSession.$account
            .map { $0?.id }
            .removeDuplicates()
            .sink { [weak downloads, weak liveActivities] ownerID in
                Task { await liveActivities?.endAll(immediate: true) }
                downloads?.setOwner(ownerID)
            }
            .store(in: &cancellables)

        preferencesStore.$preferences
            .sink { [weak liveActivities] preferences in
                liveActivities?.configure(preferences)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3(downloads.$records, downloads.$isGloballyPaused, preferencesStore.$preferences)
            .sink { [weak downloads, weak liveActivities] _, isGloballyPaused, _ in
                guard let downloads, let liveActivities else { return }
                let records = downloads.visibleRecords
                Task { await liveActivities.syncDownloads(records: records, isGloballyPaused: isGloballyPaused) }
            }
            .store(in: &cancellables)
    }

    static func preview(showOnboarding: Bool = false) -> AppEnvironment {
        let defaults = UserDefaults(suiteName: "keihatsu.preview.\(UUID().uuidString)")!
        let environment = AppEnvironment(services: .preview(), defaults: defaults)
        if !showOnboarding { environment.bootstrap.enterAsGuest() }
        return environment
    }
}

private struct AppEnvironmentModifier: ViewModifier {
    let environment: AppEnvironment
    @ObservedObject private var preferences: AppPreferencesStore

    init(environment: AppEnvironment) {
        self.environment = environment
        preferences = environment.preferencesStore
    }

    func body(content: Content) -> some View {
        content
            .environmentObject(environment)
            .environmentObject(environment.collections)
            .environmentObject(environment.libraryOptions)
            .environmentObject(environment.sources)
            .environmentObject(environment.home)
            .environmentObject(environment.search)
            .environmentObject(environment.readingHistory)
            .environmentObject(environment.navigation)
            .environmentObject(environment.bootstrap)
            .environmentObject(environment.preferencesStore)
            .environmentObject(environment.syncQueueStore)
            .environmentObject(environment.accountSession)
            .environmentObject(environment.downloads)
            .environmentObject(environment.liveActivities)
            .environment(\.keihatsuTheme, KeihatsuTheme.accented(Color(hex: preferences.preferences.theme.hex)))
            .preferredColorScheme(preferredColorScheme)
            .tint(Color(hex: preferences.preferences.theme.hex))
    }

    private var preferredColorScheme: ColorScheme? {
        switch preferences.preferences.colorScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    func appEnvironment(_ environment: AppEnvironment) -> some View {
        modifier(AppEnvironmentModifier(environment: environment))
    }
}
