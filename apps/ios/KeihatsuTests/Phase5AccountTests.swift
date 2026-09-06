import Foundation
import Testing
@testable import Keihatsu

@Suite
struct Phase5AccountTests {
    @Test @MainActor func accountCollectionChangesCannotOverwriteGuestState() {
        let store = CollectionStore(repository: FixtureCollectionRepository())
        let guest = store.snapshot
        store.applyAccountSnapshot(CollectionSnapshot(library: [], categories: [], history: []))
        _ = store.addToLibrary(
            Manga(
                id: .init(sourceID: "source-a", mangaID: "manga-a"), title: "Account title",
                url: nil, thumbnailURL: nil, description: nil, author: nil, artist: nil,
                status: nil, genres: [], language: nil
            ),
            categoryIDs: []
        )

        store.restoreGuestSnapshot()

        #expect(store.snapshot.library.map(\.id) == guest.library.map(\.id))
        #expect(store.snapshot.categories.map(\.id) == guest.categories.map(\.id))
        #expect(store.snapshot.history.map(\.id) == guest.history.map(\.id))
        #expect(!store.isAccountScoped)
    }

    @Test func preferencesDecodeExplicitSnakeCaseFields() throws {
        let json = Data(#"""
        {
          "library_display_style":"list",
          "library_items_per_row":4,
          "overlay_show_downloaded":false,
          "overlay_show_unread":true,
          "overlay_show_language":false,
          "tabs_show_categories":true,
          "tabs_show_item_count":false,
          "categories_display_mode":"compact grid",
          "source_preferences":{"manhuatop":{"enabled":true,"pinned":true}}
        }
        """#.utf8)

        let preferences = try JSONDecoder().decode(UserPreferencesDTO.self, from: json).domain

        #expect(preferences.libraryDisplayStyle == "list")
        #expect(preferences.libraryItemsPerRow == 4)
        #expect(preferences.categoriesDisplayMode == "compact grid")
        #expect(preferences.sourcePreferences["manhuatop"] == .init(enabled: true, pinned: true))
    }

    @Test func accountOutboxPersistsAndRemainsOwnerScoped() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "keihatsu-phase5-tests-" + UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = AccountDataStore(namespace: "https://api.example.test", directory: directory)
        try await first.enqueue(ownerUserID: "account-a", mutation: .updatePreferences(.default))
        try await first.enqueue(ownerUserID: "account-b", mutation: .updatePreferences(.default))

        let restored = AccountDataStore(namespace: "https://api.example.test", directory: directory)
        let accountA = await restored.outbox(ownerUserID: "account-a")
        let accountB = await restored.outbox(ownerUserID: "account-b")

        #expect(accountA.count == 1)
        #expect(accountB.count == 1)
        #expect(accountA[0].ownerUserID == "account-a")
        #expect(accountB[0].ownerUserID == "account-b")
    }

    @Test func historyTombstoneDoesNotProduceReadableProgress() throws {
        let json = Data(#"""
        {
          "id":"history-1","mangaId":"manga-1","sourceId":"source-a",
          "chapterId":"chapter-1","pageNumber":7,
          "lastReadAt":"2026-09-06T12:00:00.000Z",
          "deletedAt":"2026-09-06T12:01:00.000Z"
        }
        """#.utf8)

        let history = try JSONDecoder().decode(HistoryEntryDTO.self, from: json)

        #expect(history.progress == nil)
    }

    @Test func commentsMapNestedRepliesAndLikeState() throws {
        let json = Data(#"""
        {
          "id":"root","content":"First","images":[],"userId":"reader-1",
          "user":{"id":"reader-1","username":"Aki","avatarExpression":"happy"},
          "createdAt":"2026-09-06T12:00:00.000Z","updatedAt":"2026-09-06T12:00:00.000Z",
          "likes":2,"userLikes":[{"id":"like-1"}],
          "replies":[{
            "id":"reply","content":"Second","images":[],"userId":"reader-2",
            "createdAt":"2026-09-06T12:01:00.000Z","updatedAt":"2026-09-06T12:01:00.000Z",
            "likes":0,"userLikes":[],"replies":[]
          }]
        }
        """#.utf8)

        let comment = try JSONDecoder().decode(CommentDTO.self, from: json).domain

        #expect(comment.author.username == "Aki")
        #expect(comment.isLikedByCurrentUser)
        #expect(comment.replies.map(\.id) == ["reply"])
    }
}
