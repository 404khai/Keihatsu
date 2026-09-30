import Foundation
import Testing
@testable import Keihatsu

@Suite @MainActor
struct NotificationUnreadStoreTests {
    @Test func unreadBadgeLoadsAndTracksOptimisticChanges() async {
        let store = NotificationUnreadStore { _ in 3 }
        store.setSession("account")
        await store.refresh()
        #expect(store.count == 3)
        store.setCount(2)
        #expect(store.count == 2)
        store.setCount(3) // Failed mutation rollback.
        #expect(store.count == 3)
        store.setCount(0)
        #expect(store.count == 0)
    }

    @Test func unreadBadgeKeepsCachedCountOfflineAndClearsOnLogout() async {
        var offline = false
        let store = NotificationUnreadStore { _ in
            if offline { throw URLError(.notConnectedToInternet) }
            return 4
        }
        store.setSession("account")
        await store.refresh()
        offline = true
        await store.refresh()
        #expect(store.count == 4)
        store.setSession(nil)
        #expect(store.count == 0)
    }

    @Test func unreadBadgeRejectsAnOldAccountResponse() async {
        var continuation: CheckedContinuation<Int, any Error>?
        let store = NotificationUnreadStore { _ in
            try await withCheckedThrowingContinuation { continuation = $0 }
        }
        store.setSession("old-account")
        let request = Task { await store.refresh() }
        while continuation == nil { await Task.yield() }
        store.setSession(nil)
        continuation?.resume(returning: 8)
        await request.value
        #expect(store.count == 0)
    }

}
