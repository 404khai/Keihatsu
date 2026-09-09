import SwiftUI

@main
struct KeihatsuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .appEnvironment(environment)
                .onOpenURL { _ = environment.accountSession.handleOpenURL($0) }
        }
    }
}
