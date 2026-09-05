import Combine
import SwiftUI

enum AppRoute: Hashable {
    case feature(FeatureDestination)
}

enum PrimaryTab: String, Hashable, CaseIterable, Identifiable {
    case home = "Home"
    case library = "Library"
    case history = "History"
    case extensions = "Extensions"
    case profile = "Profile"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .library:
            return "books.vertical.fill"
        case .history:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .extensions:
            return "puzzlepiece.extension.fill"
        case .profile:
            return "person.crop.circle.fill"
        }
    }

    var destination: FeatureDestination {
        switch self {
        case .home:
            return .home
        case .library:
            return .library
        case .history:
            return .history
        case .extensions:
            return .extensions
        case .profile:
            return .profile
        }
    }
}

enum FeatureDestination: String, Hashable, CaseIterable, Identifiable {
    case home = "Home"
    case library = "Library"
    case history = "History"
    case extensions = "Extensions"
    case profile = "Profile"
    case search = "Search"
    case settings = "Settings"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .library:
            return "books.vertical.fill"
        case .history:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .extensions:
            return "puzzlepiece.extension.fill"
        case .profile:
            return "person.crop.circle.fill"
        case .search:
            return "magnifyingglass"
        case .settings:
            return "gearshape.fill"
        }
    }

    var summary: String {
        switch self {
        case .home:
            return "Content-first landing surface for discovery, promotions, and continue reading."
        case .library:
            return "Collection management, reading states, and offline affordances flow through here."
        case .history:
            return "Reading continuity, recency grouping, and quick return-to-reader flows anchor here."
        case .extensions:
            return "Source management, availability states, and plugin-style browsing live here."
        case .profile:
            return "Account surfaces, achievements, and reading identity anchor in this feature root."
        case .search:
            return "Secondary search flow with room for recents, suggestions, and source-aware filtering."
        case .settings:
            return "App preferences, reading defaults, and system-facing controls live here."
        }
    }
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: PrimaryTab = .home
    @Published var path = NavigationPath()

    func open(_ destination: FeatureDestination) {
        path.append(AppRoute.feature(destination))
    }

    func selectTab(_ tab: PrimaryTab) {
        selectedTab = tab
    }

    func resetToRoot() {
        path = NavigationPath()
    }
}
