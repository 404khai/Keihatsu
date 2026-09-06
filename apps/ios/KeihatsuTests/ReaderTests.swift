import Foundation
import Testing
@testable import Keihatsu

@Suite
struct ReaderPersistenceTests {
    private let mangaID = MangaIdentity(sourceID: "source", mangaID: "manga")

    private func manga() -> Manga {
        Manga(id: mangaID, title: "Title", url: nil, thumbnailURL: nil, description: nil, author: nil, artist: nil, status: nil, genres: [], language: "en")
    }

    private func chapter(_ number: Double) -> Chapter {
        Chapter(
            id: ChapterIdentity(manga: mangaID, chapterID: "chapter-\(Int(number))"),
            name: "Chapter \(Int(number))",
            number: number,
            uploadedAt: nil,
            url: nil,
            scanlator: nil
        )
    }

    @Test func chapterSequenceMovesChronologicallyAcrossNewestFirstInput() throws {
        let one = chapter(1), two = chapter(2), three = chapter(3)
        let sequence = ChapterSequence([two, one, three])
        #expect(sequence.chapters.map(\.number) == [3, 2, 1])
        #expect(sequence.chapter(after: one)?.id == two.id)
        #expect(sequence.chapter(before: two)?.id == one.id)
        #expect(sequence.chapter(after: three) == nil)
    }

    @Test func progressRestoresExactPageAnchorAndActiveTime() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "keihatsu-reader-tests-\(UUID())", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let value = ReaderProgressRecord(
            manga: manga(), chapter: chapter(1), pageIndex: 7, intraPageAnchor: 0.42,
            totalPages: 18, activeReadingSeconds: 91, isRead: false, isBookmarked: true, updatedAt: .now
        )
        let store = ReaderProgressStore(namespace: "origin", directory: root)
        try await store.save(value)

        let restored = ReaderProgressStore(namespace: "origin", directory: root)
        let record = try #require(await restored.progress(for: value.id))
        #expect(record.pageIndex == 7)
        #expect(record.intraPageAnchor == 0.42)
        #expect(record.activeReadingSeconds == 91)
        #expect(record.isBookmarked)
    }

    @Test func localHistoryAlsoUpdatesMangaDetailResumeState() async throws {
        let details = MangaDetailsStore(namespace: "reader-test", persistToDisk: false)
        let progress = ReaderProgressStore(namespace: "reader-test", persistToDisk: false)
        let repository = await LocalHistoryRepository(progressStore: progress, detailsStore: details)
        let manga = manga(), chapter = chapter(1)
        _ = try await details.mergeMetadata(manga)
        _ = try await details.mergeChapters([chapter], for: manga.id)
        try await repository.saveProgress(ReaderProgressRecord(
            manga: manga, chapter: chapter, pageIndex: 11, intraPageAnchor: 0.2,
            totalPages: 12, activeReadingSeconds: 12, isRead: true, isBookmarked: false, updatedAt: .now
        ))
        let record = try #require(await details.record(for: manga.id))
        #expect(record.state(for: chapter.id).pageIndex == 11)
        #expect(record.state(for: chapter.id).isRead)
    }

    @Test func recentHistoryKeepsOnlyLatestChapterForEachManga() async throws {
        let store = ReaderProgressStore(namespace: "reader-test", persistToDisk: false)
        let earlier = ReaderProgressRecord(
            manga: manga(), chapter: chapter(1), pageIndex: 4, intraPageAnchor: 0,
            totalPages: 20, activeReadingSeconds: 10, isRead: false, isBookmarked: false,
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        let latest = ReaderProgressRecord(
            manga: manga(), chapter: chapter(2), pageIndex: 8, intraPageAnchor: 0.25,
            totalPages: 24, activeReadingSeconds: 20, isRead: false, isBookmarked: false,
            updatedAt: Date(timeIntervalSince1970: 200)
        )

        try await store.save(earlier)
        try await store.save(latest)

        let recent = await store.recent()
        #expect(recent.count == 1)
        #expect(recent.first?.chapter.id == latest.chapter.id)
        #expect(recent.first?.pageIndex == latest.pageIndex)
    }
}

@Suite @MainActor
struct ReaderViewModelTests {
    @Test func singlePageChapterPersistsAsReadWithZeroBasedPosition() async throws {
        let mangaID = MangaIdentity(sourceID: "source", mangaID: "manga")
        let manga = Manga(id: mangaID, title: "Title", url: nil, thumbnailURL: nil, description: nil, author: nil, artist: nil, status: nil, genres: [], language: nil)
        let chapter = Chapter(id: .init(manga: mangaID, chapterID: "one"), name: "One", number: 1, uploadedAt: nil, url: nil, scanlator: nil)
        let historyRepository = ReaderHistoryRepositorySpy()
        let history = ReadingHistoryModel(repository: historyRepository)
        let model = ReaderViewModel(
            manga: manga,
            chapters: [chapter],
            context: ReaderLaunchContext(chapter: chapter.id, origin: .details, pageIndex: nil),
            reader: ReaderRepositoryStub(pageCount: 1),
            history: history,
            imagePipeline: ImagePipeline(configuration: APIConfiguration(baseURLString: "https://example.test")),
            incognito: false
        )

        await model.load()
        await model.flush()
        let saved = try #require(await historyRepository.lastProgress)
        #expect(saved.pageIndex == 0)
        #expect(saved.totalPages == 1)
        #expect(saved.isRead)
        guard case .started(_, let startedChapter, _) = model.sessionEvent else {
            Issue.record("Reader session did not expose its typed start event")
            return
        }
        #expect(startedChapter == chapter.id)
    }

    @Test func incognitoSuppressesAutomaticProgressButKeepsExplicitBookmark() async throws {
        let mangaID = MangaIdentity(sourceID: "source", mangaID: "manga")
        let manga = Manga(id: mangaID, title: "Title", url: nil, thumbnailURL: nil, description: nil, author: nil, artist: nil, status: nil, genres: [], language: nil)
        let chapter = Chapter(id: .init(manga: mangaID, chapterID: "one"), name: "One", number: 1, uploadedAt: nil, url: nil, scanlator: nil)
        let historyRepository = ReaderHistoryRepositorySpy()
        let history = ReadingHistoryModel(repository: historyRepository)
        let model = ReaderViewModel(
            manga: manga,
            chapters: [chapter],
            context: ReaderLaunchContext(chapter: chapter.id, origin: .details, pageIndex: nil),
            reader: ReaderRepositoryStub(pageCount: 1),
            history: history,
            imagePipeline: ImagePipeline(configuration: APIConfiguration(baseURLString: "https://example.test")),
            incognito: true
        )

        await model.load()
        await model.flush()
        #expect(await historyRepository.savedCount == 0)
        await model.toggleBookmark()
        #expect(await historyRepository.bookmarkCount == 1)
    }
}

private actor ReaderRepositoryStub: ReaderRepository {
    let pageCount: Int
    init(pageCount: Int) { self.pageCount = pageCount }
    func pages(for chapter: Chapter, manga: Manga) -> [ReaderPage] {
        (0..<pageCount).map { index in
            ReaderPage(id: .init(chapter: chapter.id, index: index), imageURL: URL(string: "https://example.test/\(index).jpg")!, refererURL: nil)
        }
    }
}

private actor ReaderHistoryRepositorySpy: HistoryRepository {
    private(set) var savedCount = 0
    private(set) var bookmarkCount = 0
    private(set) var lastProgress: ReaderProgressRecord?
    func progress(for chapter: ChapterIdentity) -> ReaderProgressRecord? { nil }
    func recentProgress() -> [ReaderProgressRecord] { [] }
    func saveProgress(_ progress: ReaderProgressRecord) {
        savedCount += 1
        lastProgress = progress
    }
    func toggleBookmark(manga: Manga, chapter: Chapter) -> Bool {
        bookmarkCount += 1
        return true
    }
    func deleteProgress(for manga: MangaIdentity) {}
}
