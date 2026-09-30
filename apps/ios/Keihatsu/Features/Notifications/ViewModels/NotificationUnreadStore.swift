import Combine
import Foundation

/// The account's Inbox badge stays available when the Inbox sheet is closed.
@MainActor
final class NotificationUnreadStore: ObservableObject {
    @Published private(set) var count = 0
    private var token: String?
    private var revision = 0
    private let loadCount: (String) async throws -> Int

    init(loadCount: @escaping (String) async throws -> Int) {
        self.loadCount = loadCount
    }

    func setSession(_ token: String?) {
        guard self.token != token else { return }
        self.token = token
        setCount(0)
    }

    func setCount(_ value: Int) {
        revision += 1
        count = max(0, value)
    }

    func refresh() async {
        guard let token else { return }
        revision += 1
        let requestRevision = revision
        do {
            let value = try await loadCount(token)
            guard self.token == token, revision == requestRevision else { return }
            setCount(value)
        } catch {
            // Keep the last known count while offline.
        }
    }

    func pollWhileActive() async {
        while !Task.isCancelled {
            await refresh()
            do { try await Task.sleep(for: .seconds(30)) }
            catch { return }
        }
    }
}
