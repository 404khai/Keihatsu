import Combine
import Foundation

@MainActor
final class MangaDetailsViewModel: ObservableObject {
    let seed: MangaDetailsSeed
    let origin: ReaderLaunchContext.Origin
    private let repository: any MangaDetailsRepository

    @Published private(set) var manga: Manga
    @Published private(set) var chapters: [Chapter]
    @Published private(set) var states: [String: ChapterReadingState] = [:]
    @Published private(set) var recommendations: [Manga] = []
    @Published private(set) var metadataLoading = false
    @Published private(set) var chaptersLoading = false
    @Published private(set) var recommendationsLoading = false
    @Published private(set) var metadataError: String?
    @Published private(set) var chaptersError: String?
    @Published private(set) var recommendationsError: String?
    @Published var filter = ChapterFilter()
    @Published var showsAllChapters = false
    @Published var showsFullDescription = false

    init(seed: MangaDetailsSeed, origin: ReaderLaunchContext.Origin, repository: any MangaDetailsRepository) {
        self.seed = seed
        self.origin = origin
        self.repository = repository
        manga = seed.manga
        chapters = ChapterOrdering.newestFirst(seed.fallbackChapters)
    }

    var filteredChapters: [Chapter] {
        chapters.filter { filter.includes($0, state: state(for: $0)) }
    }

    var displayedChapters: [Chapter] {
        showsAllChapters ? filteredChapters : Array(filteredChapters.prefix(3))
    }

    var activeFilterCount: Int {
        [filter.downloaded, filter.unread, filter.bookmarked].filter { $0 }.count
    }

    var resumeChapter: ResumeChapter? {
        ResolveResumeChapter.callAsFunction(chapters: chapters, states: states)
    }

    func state(for chapter: Chapter) -> ChapterReadingState {
        states[chapter.id.chapterID] ?? ChapterReadingState()
    }

    func load() async {
        if let cached = await repository.cachedRecord(for: manga.id) {
            if !cached.manga.title.isEmpty { manga = cached.manga }
            if !cached.chapters.isEmpty { chapters = ChapterOrdering.newestFirst(cached.chapters) }
            states = cached.chapterStates
        }
        guard !seed.isLocalFixture else { return }
        async let metadata: Void = refreshMetadata()
        async let chapterList: Void = refreshChapters()
        async let related: Void = refreshRecommendations()
        _ = await (metadata, chapterList, related)
    }

    func refreshAll() async {
        guard !seed.isLocalFixture else { return }
        async let metadata: Void = refreshMetadata()
        async let chapterList: Void = refreshChapters()
        async let related: Void = refreshRecommendations()
        _ = await (metadata, chapterList, related)
    }

    func refreshMetadata() async {
        metadataLoading = true
        metadataError = nil
        defer { metadataLoading = false }
        do { manga = try await repository.refreshMetadata(for: manga.id) }
        catch { metadataError = error.localizedDescription }
    }

    func refreshChapters() async {
        chaptersLoading = true
        chaptersError = nil
        defer { chaptersLoading = false }
        do {
            chapters = try await repository.refreshChapters(for: manga.id)
            if let cached = await repository.cachedRecord(for: manga.id) { states = cached.chapterStates }
        } catch { chaptersError = error.localizedDescription }
    }

    func refreshRecommendations() async {
        recommendationsLoading = true
        recommendationsError = nil
        defer { recommendationsLoading = false }
        do { recommendations = try await repository.recommendations(for: manga.id) }
        catch { recommendationsError = error.localizedDescription }
    }

    func toggleRead(_ chapter: Chapter) async {
        await update(chapter) { $0.isRead.toggle() }
    }

    func toggleBookmark(_ chapter: Chapter) async {
        await update(chapter) { $0.isBookmarked.toggle() }
    }

    func readerContext(for chapter: Chapter, pageIndex: Int? = nil) async -> ReaderLaunchContext {
        let pageIndex = pageIndex ?? state(for: chapter).pageIndex
        return ReaderLaunchContext(chapter: chapter.id, origin: origin, pageIndex: pageIndex)
    }

    private func update(_ chapter: Chapter, mutation: @escaping @Sendable (inout ChapterReadingState) -> Void) async {
        var optimistic = state(for: chapter)
        mutation(&optimistic)
        states[chapter.id.chapterID] = optimistic
        guard !seed.isLocalFixture else { return }
        do { states = try await repository.updateState(for: chapter.id, mutation).chapterStates }
        catch { chaptersError = error.localizedDescription }
    }
}
