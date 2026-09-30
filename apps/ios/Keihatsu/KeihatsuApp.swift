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
                    if !environment.navigation.handleLiveActivityURL(url) &&
                        !environment.navigation.handleNotificationURL(url) {
                        _ = environment.accountSession.handleOpenURL(url)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .keihatsuPushOpened)) { event in
                    if let url = event.object as? URL { _ = environment.navigation.handleNotificationURL(url) }
                    Task { await environment.notificationUnread.refresh() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .keihatsuPushReceived)) { _ in
                    Task { await environment.notificationUnread.refresh() }
                }
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    await SeasonalAppIconManager.shared.sync()
                    await environment.notificationUnread.pollWhileActive()
                }
        }
    }
}
