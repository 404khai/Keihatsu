import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let services: AppServices
    let theme: KeihatsuTheme
    let preferencesStore: AppPreferencesStore
    let syncQueueStore: SyncQueueStore

    init(
        services: AppServices = .preview,
        theme: KeihatsuTheme? = nil,
        preferencesStore: AppPreferencesStore? = nil,
        syncQueueStore: SyncQueueStore? = nil
    ) {
        self.services = services
        self.theme = theme ?? .default
        self.preferencesStore = preferencesStore ?? AppPreferencesStore()
        self.syncQueueStore = syncQueueStore ?? SyncQueueStore()
    }
}

struct AppServices {
    let apiBaseURL: URL?
    let imageHostURL: URL?
    let readerPrefetchWindow: Int

    static let preview = AppServices(
        apiBaseURL: nil,
        imageHostURL: nil,
        readerPrefetchWindow: 3
    )
}
