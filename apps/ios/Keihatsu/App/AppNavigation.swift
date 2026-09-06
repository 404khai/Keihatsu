import Combine
import SwiftUI

/// State only. ContentView continues to own tab layout and destination placement.
@MainActor
final class AppNavigation: ObservableObject {
    enum Tab: Hashable { case home, library, history, extensions, profile, search }

    @Published var selectedTab: Tab = .library
    @Published var homePath = NavigationPath()
    @Published var libraryPath = NavigationPath()
    @Published var historyPath = NavigationPath()
    @Published var extensionsPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var searchPath = NavigationPath()

    func reset() {
        selectedTab = .library
        homePath = NavigationPath()
        libraryPath = NavigationPath()
        historyPath = NavigationPath()
        extensionsPath = NavigationPath()
        profilePath = NavigationPath()
        searchPath = NavigationPath()
    }
}

/// Contracts for future API-backed destinations. Sample screens keep their existing routes.
nonisolated enum ContentRoute: Hashable, Sendable {
    case manga(MangaIdentity)
    case reader(ReaderLaunchContext)
}
