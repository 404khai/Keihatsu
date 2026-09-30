import Foundation
import Testing
@testable import Keihatsu

@Suite @MainActor
struct NotificationTests {
    @Test func mapsInboxPayloadAndUnreadState() throws {
        let json = """
        {"items":[{"id":"n1","type":"CHAPTER_UPDATE","title":"New chapter",\
        "body":"Open the manga","deepLink":"keihatsu://chapter/source/manga/chapter",\
        "sourceId":"source","mangaId":"manga","chapterId":"chapter",\
        "commentId":null,"threadId":null,"createdAt":"2026-09-30T10:00:00.000Z","readAt":null}],\
        "nextCursor":"n1"}
        """
        let page = try JSONDecoder().decode(InboxPageDTO.self, from: Data(json.utf8))
        #expect(page.nextCursor == "n1")
        #expect(page.items.first?.isRead == false)
        #expect(page.items.first?.chapterId == "chapter")
    }

    @Test func notificationRoutesUseOrdinaryNavigation() throws {
        let navigation = AppNavigation()
        #expect(navigation.handleNotificationURL(try #require(URL(string: "keihatsu://chapter/source/manga/chapter"))))
        #expect(navigation.selectedTab == .library)
        #expect(navigation.handleNotificationURL(try #require(URL(string: "keihatsu://manga/source/manga"))))
        #expect(navigation.handleNotificationURL(try #require(URL(string: "keihatsu://chapter"))))
        #expect(navigation.inboxRequested)
    }
}
