import Combine
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    let services: AppServices
    let navigation: AppNavigation
    let bootstrap: AppBootstrap
    let preferencesStore: AppPreferencesStore
    let syncQueueStore: SyncQueueStore

    init(services: AppServices = .live(), defaults: UserDefaults = .standard) {
        self.services = services
        navigation = AppNavigation()
        bootstrap = AppBootstrap(defaults: defaults)
        preferencesStore = AppPreferencesStore(userDefaults: defaults)
        syncQueueStore = SyncQueueStore()
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
            .environmentObject(environment.navigation)
            .environmentObject(environment.bootstrap)
            .environmentObject(environment.preferencesStore)
            .environmentObject(environment.syncQueueStore)
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
