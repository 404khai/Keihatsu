import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            await SeasonalAppIconManager.shared.sync()
        }
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping @Sendable () -> Void
    ) {
        BackgroundSessionCompletionRegistry.shared.register(identifier: identifier, completion: completionHandler)
    }
}
