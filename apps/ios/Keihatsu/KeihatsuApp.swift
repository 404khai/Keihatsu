import SwiftUI

@main
struct KeihatsuApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .appEnvironment(environment)
        }
    }
}
