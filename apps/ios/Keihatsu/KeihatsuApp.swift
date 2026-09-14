import SwiftUI

@main
struct KeihatsuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .appEnvironment(environment)
                .onOpenURL { url in
                    if !environment.navigation.handleLiveActivityURL(url) {
                        _ = environment.accountSession.handleOpenURL(url)
                    }
                }
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    await SeasonalAppIconManager.shared.sync()
                }
        }
    }
}
