import Foundation
import Testing
@testable import Keihatsu

@Suite
struct LiveActivityTests {
    @Test func aggregateDownloadProjectionUsesRealQueueStateAndPrivacyDefault() throws {
        let first = makeDownload(status: .completed, progress: 1, priority: 0, title: "First Manga")
        let second = makeDownload(status: .downloading, progress: 0.4, priority: 1, title: "Second Manga")

        let projection = try #require(DownloadLiveActivityProjection.make(
            records: [second, first],
            trackedRecordIDs: [first.id, second.id],
            batchID: UUID(),
            isGloballyPaused: false,
            showsDetails: false
        ))

        #expect(projection.completedChapters == 1)
        #expect(projection.totalChapters == 2)
        #expect(projection.progress == 0.7)
        #expect(projection.status == .downloading)
        #expect(projection.mangaTitle == "Chapter downloads")
        #expect(projection.chapterName == "Keihatsu")
    }

    @Test func aggregateDownloadProjectionEndsOnPauseWaitFailureAndCompletion() throws {
        let paused = try #require(DownloadLiveActivityProjection.make(
            records: [makeDownload(status: .paused, progress: 0.25)],
            trackedRecordIDs: [], batchID: UUID(), isGloballyPaused: true, showsDetails: true
        ))
        let waiting = try #require(DownloadLiveActivityProjection.make(
            records: [makeDownload(status: .waitingForWiFi, progress: 0.25)],
            trackedRecordIDs: [], batchID: UUID(), isGloballyPaused: false, showsDetails: true
        ))
        let failed = try #require(DownloadLiveActivityProjection.make(
            records: [makeDownload(status: .failed, progress: 0.25)],
            trackedRecordIDs: [], batchID: UUID(), isGloballyPaused: false, showsDetails: true
        ))
        let completedRecord = makeDownload(status: .completed, progress: 1)
        let completed = try #require(DownloadLiveActivityProjection.make(
            records: [completedRecord],
            trackedRecordIDs: [completedRecord.id], batchID: UUID(), isGloballyPaused: false, showsDetails: true
        ))

        #expect(paused.status == .paused && paused.hasUnfinishedWork)
        #expect(waiting.status == .waitingForWiFi && waiting.hasUnfinishedWork)
        #expect(failed.status == .failed && failed.hasUnfinishedWork)
        #expect(completed.status == .completed && !completed.hasUnfinishedWork)
    }

    @Test func detailedDownloadProjectionUsesMangaAndChapterNames() throws {
        let record = makeDownload(status: .downloading, progress: 0.4, title: "Second Manga")
        let projection = try #require(DownloadLiveActivityProjection.make(
            records: [record],
            trackedRecordIDs: [record.id],
            batchID: UUID(),
            isGloballyPaused: false,
            showsDetails: true
        ))

        #expect(projection.mangaTitle == "Second Manga")
        #expect(projection.chapterName == "Chapter 1")
    }

    @Test func readingLinkTracksCurrentChapterAndRoundTripsOpaqueIDs() throws {
        let state = ReadingActivityAttributes.ContentState(
            mangaTitle: "A Manga", chapterName: "Chapter 2.5",
            sourceID: "source/日本", mangaID: "manga?id=7", chapterID: "chapter/2.5?lang=en",
            currentPage: 9, totalPages: 20, status: .reading, updatedAt: .now
        )
        let url = try #require(LiveActivityLink.reader(
            attributes: ReadingActivityAttributes(sessionID: UUID()),
            state: state
        ))
        let destination = try #require(LiveActivityDestination(url: url))

        guard case .reader(let manga, let context) = destination else {
            Issue.record("Expected a reader destination")
            return
        }
        #expect(manga.sourceID == state.sourceID)
        #expect(manga.mangaID == state.mangaID)
        #expect(context.chapter.chapterID == state.chapterID)
        #expect(context.pageIndex == 8)
    }

    @Test func systemRoutesRejectForeignSchemesAndHandleDuplicateQueries() throws {
        #expect(LiveActivityDestination(url: URL(string: "https://example.com/downloads")!) == nil)
        #expect(LiveActivityDestination(url: URL(string: "keihatsu://privacy")!) == .privacy)
        let repeated = URL(string: "keihatsu://reader?source=first&source=second&manga=m&chapter=c&page=-3")!
        let destination = try #require(LiveActivityDestination(url: repeated))
        guard case .reader(let manga, let context) = destination else {
            Issue.record("Expected a reader destination")
            return
        }
        #expect(manga.sourceID == "first")
        #expect(context.pageIndex == 0)
    }

    @Test @MainActor func tappingVisibleReaderActivityDoesNotAddAnotherReader() throws {
        let navigation = AppNavigation()
        let chapter = ChapterIdentity(
            manga: MangaIdentity(sourceID: "source", mangaID: "manga"),
            chapterID: "chapter"
        )
        navigation.selectedTab = .history
        navigation.historyPath.append("visible-reader")
        navigation.readerDidAppear(chapter: chapter)

        let handled = navigation.handleLiveActivityURL(
            URL(string: "keihatsu://reader?source=source&manga=manga&chapter=chapter&page=4")!
        )

        #expect(handled)
        #expect(navigation.selectedTab == .history)
        #expect(navigation.historyPath.count == 1)
        #expect(navigation.libraryPath.isEmpty)
    }

    @Test @MainActor func tappingAnotherActivityPushesThroughLibraryNavigation() throws {
        let navigation = AppNavigation()
        navigation.selectedTab = .profile
        navigation.libraryPath.append("stale-detail")

        let handled = navigation.handleLiveActivityURL(
            URL(string: "keihatsu://reader?source=source&manga=manga&chapter=chapter&page=4")!
        )

        #expect(handled)
        #expect(navigation.selectedTab == .library)
        #expect(navigation.libraryPath.count == 1)
    }

    @Test func legacyPreferencesShowLiveActivityDetailsByDefault() throws {
        let preferences = try JSONDecoder().decode(LocalUserPreferences.self, from: Data("{}".utf8))

        #expect(preferences.readingLiveActivitiesEnabled)
        #expect(preferences.downloadLiveActivitiesEnabled)
        #expect(preferences.showLiveActivityMangaDetails)
    }

    @Test @MainActor func existingPrivatePreferenceMigratesOnceAndRemainsUserControlled() throws {
        let defaults = try #require(UserDefaults(suiteName: "keihatsu.live-activity-tests.\(UUID())"))
        var preferences = LocalUserPreferences.default
        preferences.showLiveActivityMangaDetails = false
        defaults.set(try JSONEncoder().encode(preferences), forKey: "keihatsu.localUserPreferences")

        let migrated = AppPreferencesStore(userDefaults: defaults)
        #expect(migrated.preferences.showLiveActivityMangaDetails)

        migrated.preferences.showLiveActivityMangaDetails = false
        let restored = AppPreferencesStore(userDefaults: defaults)
        #expect(!restored.preferences.showLiveActivityMangaDetails)
    }

    @Test func representativeActivityPayloadsStayBelowActivityKitLimit() throws {
        let reading = ReadingActivityAttributes.ContentState(
            mangaTitle: String(repeating: "M", count: 120),
            chapterName: String(repeating: "C", count: 80),
            sourceID: "source", mangaID: "manga", chapterID: "chapter",
            currentPage: 24, totalPages: 60, status: .reading, updatedAt: .now
        )
        let download = DownloadActivityAttributes.ContentState(
            mangaTitle: String(repeating: "M", count: 120),
            chapterName: String(repeating: "C", count: 80),
            completedChapters: 4, totalChapters: 10, progress: 0.45,
            status: .downloading, updatedAt: .now
        )
        let encodedSize = try JSONEncoder().encode(reading).count + JSONEncoder().encode(download).count

        #expect(encodedSize < 4_096)
    }

    private func makeDownload(
        status: DownloadStatus,
        progress: Double,
        priority: Int = 0,
        title: String = "Manga"
    ) -> ChapterDownloadRecord {
        ChapterDownloadRecord(
            id: UUID(),
            request: ChapterDownloadRequest(
                identity: DownloadIdentity(sourceID: "source", mangaID: title, chapterID: "chapter-\(priority)"),
                ownerID: "guest", extensionName: "Source", mangaTitle: title,
                chapterName: "Chapter \(priority + 1)", chapterNumber: Double(priority + 1), thumbnailURL: nil
            ),
            status: status, pages: [], activePageIndex: nil, activeTaskIdentifier: nil,
            priority: priority, progress: progress, errorMessage: nil, archiveByteCount: 0,
            createdAt: .now, updatedAt: .now
        )
    }
}
