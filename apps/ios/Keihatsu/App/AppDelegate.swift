import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { await PushRegistrationCoordinator.shared.receivedDeviceToken(deviceToken) }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        NotificationCenter.default.post(name: .keihatsuPushReceived, object: nil)
        return [.list, .banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse) async {
        PushRegistrationCoordinator.shared.openedNotification(response.notification.request.content.userInfo)
    }
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
