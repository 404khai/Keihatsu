import Foundation
import Testing
@testable import Keihatsu

@Suite struct ReadingStatisticsTests {
    private let now = Date(timeIntervalSince1970: 1_791_288_000) // 2026-10-06 UTC

    @Test func emptyAndLegacyStatisticsDoNotInventTime() throws {
        let json = Data(#"{"libraryCount":0,"totalReadingTimeMinutes":42,"mangasReadToday":0,"commentsCount":0,"points":0}"#.utf8)
        let legacy = try JSONDecoder().decode(UserStatistics.self, from: json)
        #expect(legacy.dailyReadingTimeMinutes == nil)
        let stats = ReadingStatistics(statistics: legacy, history: [], now: now)
        #expect(stats.weekMinutes == 0)
        #expect(stats.daily.count == 7)
        #expect(stats.monthly.count == 6)
        #expect(stats.genres.isEmpty)
    }

    @Test func accountResponseDecodesDailyMinutes() throws {
        let json = Data(#"{"dailyReadingTimeMinutes":{"2026-10-01":1.5}}"#.utf8)
        let dto = try JSONDecoder().decode(UserStatisticsDTO.self, from: json)
        #expect(dto.domain.dailyReadingTimeMinutes == ["2026-10-01": 1.5])
    }

    @Test func dailyTimeUsesUtcBoundariesAndPreservesFractionalMinutes() throws {
        let now = try #require(APIDate.parse("2026-10-01T12:00:00Z"))
        var account = UserStatistics.empty
        account.dailyReadingTimeMinutes = ["2026-09-24": 20, "2026-09-25": 30.5, "2026-10-01": 60, "2026-10-02": 99]
        let stats = ReadingStatistics(statistics: account, history: [], now: now)
        #expect(stats.weekMinutes == 90.5)
        #expect(stats.previousWeekMinutes == 20)
        #expect(stats.daily.first?.minutes == 30.5)
        #expect(stats.monthly.last?.hours == 1)
        #expect(stats.activeDays == 3)
        #expect(stats.streak == 1)
    }

    @Test func statisticsIncludeEveryChapterWhileHistoryKeepsOneRowPerTitle() async throws {
        let manga = Manga(id: .init(sourceID: "a", mangaID: "same"), title: "Title", url: nil,
                          thumbnailURL: nil, description: nil, author: nil, artist: nil,
                          status: nil, genres: ["Action", "Action", "Fantasy"], language: nil)
        let store = ReaderProgressStore(namespace: "stats-test", persistToDisk: false)
        for number in 1...3 {
            let chapter = Chapter(id: .init(manga: manga.id, chapterID: String(number)), name: "Chapter",
                                  number: Double(number), uploadedAt: nil, url: nil, scanlator: nil)
            try await store.save(ReaderProgressRecord(manga: manga, chapter: chapter, pageIndex: 1,
                intraPageAnchor: 0, totalPages: 2, activeReadingSeconds: 60,
                isRead: number < 3, isBookmarked: false, updatedAt: now))
        }
        #expect(await store.recent().count == 1)
        let stats = ReadingStatistics(statistics: .empty, history: await store.all(), now: now)
        #expect(stats.chaptersRead == 2)
        #expect(stats.titlesOpened == 1)
        #expect(stats.genres.map(\.percent) == [50, 50])
        #expect(stats.weekMinutes == 0)
    }
}
