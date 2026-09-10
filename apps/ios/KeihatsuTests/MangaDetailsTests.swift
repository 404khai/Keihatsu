import Foundation
import Testing
@testable import Keihatsu

@Suite
struct MangaDetailsTests {
    private let mangaID = MangaIdentity(sourceID: "source", mangaID: "manga")

    private func manga(title: String = "Title") -> Manga {
        Manga(id: mangaID, title: title, url: URL(string: "https://example.test/manga"), thumbnailURL: nil, description: "Description", author: nil, artist: nil, status: nil, genres: [], language: "en")
    }

    private func chapter(_ id: String, number: Double, date: Date? = nil) -> Chapter {
        Chapter(id: ChapterIdentity(manga: mangaID, chapterID: id), name: id, number: number, uploadedAt: date, url: nil, scanlator: nil)
    }

    @Test func chapterOrderingHandlesFractionsAndSpecialsDeterministically() {
        let specialA = chapter("Special A", number: 0, date: Date(timeIntervalSince1970: 2))
        let specialB = chapter("Special B", number: .nan, date: Date(timeIntervalSince1970: 1))
        let chapters = [chapter("1", number: 1), specialB, chapter("2.5", number: 2.5), specialA, chapter("2", number: 2)]
        #expect(ChapterOrdering.newestFirst(chapters).map(\.id.chapterID) == ["2.5", "2", "1", "Special A", "Special B"])
        #expect(ChapterOrdering.oldestFirst(chapters).map(\.id.chapterID) == ["1", "2", "2.5", "Special B", "Special A"])
    }

    @Test func resumeStartsOldestContinuesUnfinishedAndAdvancesFinished() throws {
        let chapters = [chapter("3", number: 3), chapter("1", number: 1), chapter("2", number: 2)]
        let first = try #require(ResolveResumeChapter.callAsFunction(chapters: chapters, states: [:]))
        #expect(first.chapter.id.chapterID == "1")
        #expect(!first.hasHistory)

        var states = ["1": ChapterReadingState(isRead: false, lastReadAt: .now, pageIndex: 7)]
        let unfinished = try #require(ResolveResumeChapter.callAsFunction(chapters: chapters, states: states))
        #expect(unfinished.chapter.id.chapterID == "1")
        #expect(unfinished.pageIndex == 7)

        states["1"] = ChapterReadingState(isRead: true, lastReadAt: .now, pageIndex: 12)
        let advanced = try #require(ResolveResumeChapter.callAsFunction(chapters: chapters, states: states))
        #expect(advanced.chapter.id.chapterID == "2")
        #expect(advanced.pageIndex == nil)
    }

    @Test func filtersComposeAcrossDurableFlags() {
        let chapter = chapter("1", number: 1)
        let filter = ChapterFilter(downloaded: true, unread: true, bookmarked: true)
        #expect(filter.includes(chapter, state: ChapterReadingState(isBookmarked: true, isDownloaded: true)))
        #expect(!filter.includes(chapter, state: ChapterReadingState(isRead: true, isBookmarked: true, isDownloaded: true)))
        #expect(!filter.includes(chapter, state: ChapterReadingState(isBookmarked: true)))
    }

    @Test func refreshAndRelaunchPreserveReadingState() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "keihatsu-details-tests-\(UUID())", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = MangaDetailsStore(namespace: "test-origin", directory: root)
        let chapters = [chapter("1", number: 1), chapter("2", number: 2)]
        _ = try await store.mergeMetadata(manga())
        _ = try await store.mergeChapters(chapters, for: mangaID)
        _ = try await store.updateState(for: chapters[0].id) {
            $0.isRead = true
            $0.isBookmarked = true
            $0.isDownloaded = true
            $0.pageIndex = 9
        }
        _ = try await store.mergeMetadata(manga(title: "Refreshed title"))
        _ = try await store.mergeChapters(chapters.reversed(), for: mangaID)

        let restoredStore = MangaDetailsStore(namespace: "test-origin", directory: root)
        let restored = try #require(await restoredStore.record(for: mangaID))
        #expect(restored.manga.title == "Refreshed title")
        #expect(restored.state(for: chapters[0].id).isRead)
        #expect(restored.state(for: chapters[0].id).isBookmarked)
        #expect(restored.state(for: chapters[0].id).isDownloaded)
        #expect(restored.state(for: chapters[0].id).pageIndex == 9)
    }

    @Test func readerContextKeepsCompositeIdentityOriginAndPage() {
        let chapter = chapter("opaque/chapter?id=1", number: 1)
        let context = ReaderLaunchContext(chapter: chapter.id, origin: .search, pageIndex: 4)
        #expect(context.chapter.manga.sourceID == "source")
        #expect(context.chapter.manga.mangaID == "manga")
        #expect(context.chapter.chapterID == "opaque/chapter?id=1")
        #expect(context.origin == .search)
        #expect(context.pageIndex == 4)
    }
}
