//import SwiftUI
//
//struct AppRootView: View {
//    @EnvironmentObject private var router: AppRouter
//
//    var body: some View {
//        NavigationStack(path: $router.path) {
//            RootScaffoldView()
//                .navigationDestination(for: AppRoute.self) { route in
//                    destinationView(for: route)
//                }
//        }
//    }
//
//    @ViewBuilder
//    private func destinationView(for route: AppRoute) -> some View {
//        switch route {
//        case .feature(let destination):
//            featureView(for: destination)
//        }
//    }
//
//    @ViewBuilder
//    private func featureView(for destination: FeatureDestination) -> some View {
//        switch destination {
//        case .home:
//            HomeView()
//        case .library:
//            LibraryView()
//        case .history:
//            HistoryView()
//        case .extensions:
//            ExtensionsView()
//        case .profile:
//            ProfileView()
//        case .search:
//            SearchView()
//        case .settings:
//            SettingsView()
//        }
//    }
//}
