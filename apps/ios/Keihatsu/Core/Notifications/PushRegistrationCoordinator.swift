import Foundation
import UIKit
import UserNotifications

@MainActor
final class PushRegistrationCoordinator {
    static let shared = PushRegistrationCoordinator()
    private let defaults = UserDefaults.standard
    private var api: NotificationsAPI?
    private var bearerToken: String?
    private var deviceToken: String?
    private(set) var pendingURL: URL?

    var installationID: String {
        if let id = defaults.string(forKey: "pushInstallationID") { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: "pushInstallationID")
        return id
    }

    func configure(api: NotificationsAPI) { self.api = api }

    func signedIn(token: String) async {
        bearerToken = token
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted { UIApplication.shared.registerForRemoteNotifications() }
        await registerIfReady()
    }

    func receivedDeviceToken(_ data: Data) async {
        deviceToken = data.map { String(format: "%02x", $0) }.joined()
        await registerIfReady()
    }

    private func registerIfReady() async {
        guard let api, let bearerToken, let deviceToken else { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        try? await api.register(token: bearerToken, installationID: installationID,
                                deviceToken: deviceToken, version: version)
    }

    func signedOut(token: String?) async {
        if let api, let token { try? await api.unregister(token: token, installationID: installationID) }
        bearerToken = nil
    }

    func openedNotification(_ info: [AnyHashable: Any]) {
        guard let value = info["deepLink"] as? String,
              let url = URL(string: value), url.scheme == "keihatsu" else { return }
        pendingURL = url
        NotificationCenter.default.post(name: .keihatsuPushOpened, object: url)
    }

    func takePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }
}

extension Notification.Name {
    static let keihatsuPushOpened = Notification.Name("keihatsuPushOpened")
    static let keihatsuPushReceived = Notification.Name("keihatsuPushReceived")
}
