import Combine
import Foundation

nonisolated struct ReaderScrollRequest: Identifiable, Equatable, Sendable {
    let id = UUID()
    let page: ReaderPage.ID
    let anchor: Double
}

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var loadedChapters: [LoadedReaderChapter] = []
    @Published private(set) var currentPage: ReaderPage.ID?
    @Published private(set) var currentAnchor = 0.0
    @Published private(set) var isLoading = false
    @Published private(set) var isAppending = false
    @Published private(set) var loadError: String?
    @Published private(set) var appendError: String?
    @Published private(set) var isBookmarked = false
    @Published private(set) var sessionEvent: ReaderSessionEvent?
    @Published var controlsVisible = true
    @Published var scrollRequest: ReaderScrollRequest?

    let manga: Manga
    let context: ReaderLaunchContext
    private let sequence: ChapterSequence
    private let reader: any ReaderRepository
    private let history: ReadingHistoryModel
    private let prefetcher: PagePrefetcher
    private let session = ReaderSession()
    private let incognito: Bool
    private var saveTask: Task<Void, Never>?
    private var hasStarted = false
    private let retainedChapterLimit = 5

    init(
        manga: Manga,
        chapters: [Chapter],
        context: ReaderLaunchContext,
        reader: any ReaderRepository,
        history: ReadingHistoryModel,
        imagePipeline: ImagePipeline,
        incognito: Bool
    ) {
        self.manga = manga
        self.context = context
        sequence = ChapterSequence(chapters)
        self.reader = reader
        self.history = history
        prefetcher = PagePrefetcher(pipeline: imagePipeline)
        self.incognito = incognito
    }

    var currentLoadedChapter: LoadedReaderChapter? {
        guard let currentPage else { return loadedChapters.first }
        return loadedChapters.first { $0.id == currentPage.chapter }
    }

    var currentChapter: Chapter? { currentLoadedChapter?.chapter }
    var currentPages: [ReaderPage] { currentLoadedChapter?.pages ?? [] }
    var currentPageIndex: Int { currentPage?.index ?? 0 }
    var displayedPage: Int { currentPages.isEmpty ? 0 : min(currentPageIndex + 1, currentPages.count) }
    var hasOlderChapter: Bool { currentChapter.flatMap(sequence.chapter(before:)) != nil }
    var hasNewerChapter: Bool { currentChapter.flatMap(sequence.chapter(after:)) != nil }

    func load() async {
        guard !hasStarted else { return }
        hasStarted = true
        guard let initial = sequence.chapters.first(where: { $0.id == context.chapter }) ?? sequence.chapters.last else {
            loadError = "This title has no readable chapters."
            return
        }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let pages = try await reader.pages(for: initial, manga: manga)
            guard !pages.isEmpty else { throw APIError.http(status: 404, message: "No pages found for \(initial.name).") }
            loadedChapters = [LoadedReaderChapter(chapter: initial, pages: pages)]
            let saved = await history.progress(for: initial.id)
            let index = min(max(saved?.pageIndex ?? context.pageIndex ?? 0, 0), pages.count - 1)
            currentPage = pages[index].id
            currentAnchor = min(max(saved?.intraPageAnchor ?? 0, 0), 1)
            isBookmarked = saved?.isBookmarked ?? false
            scrollRequest = ReaderScrollRequest(page: pages[index].id, anchor: currentAnchor)
            session.start(chapter: initial.id)
            sessionEvent = session.latestEvent
            prefetcher.update(around: pages[index], in: pages)
        } catch {
            loadError = error.localizedDescription
        }
    }

    func retryLoad() async {
        hasStarted = false
        await load()
    }

    func didDisplay(_ page: ReaderPage, anchor: Double) {
        guard page.id != currentPage || abs(anchor - currentAnchor) > 0.04 else { return }
        let changedChapter = page.id.chapter != currentPage?.chapter
        currentPage = page.id
        currentAnchor = min(max(anchor, 0), 1)
        session.visible(page.id)
        sessionEvent = session.latestEvent
        if changedChapter {
            isBookmarked = false
            Task { [weak self] in
                guard let self, let saved = await history.progress(for: page.id.chapter),
                      currentPage?.chapter == page.id.chapter else { return }
                isBookmarked = saved.isBookmarked
            }
        }
        if let loaded = loadedChapters.first(where: { $0.id == page.id.chapter }) {
            prefetcher.update(around: page, in: loaded.pages)
            if loaded.id == loadedChapters.last?.id, page.id.index >= max(loaded.pages.count - 2, 0) {
                Task { await appendNextChapter() }
            }
        }
        scheduleSave()
    }

    func scrub(to pageIndex: Int) {
        guard !currentPages.isEmpty else { return }
        let page = currentPages[min(max(pageIndex, 0), currentPages.count - 1)]
        currentPage = page.id
        currentAnchor = 0
        scrollRequest = ReaderScrollRequest(page: page.id, anchor: 0)
        session.visible(page.id)
        sessionEvent = session.latestEvent
        scheduleSave()
    }

    func openOlderChapter() async {
        guard let currentChapter else { return }
        await open(sequence.chapter(before: currentChapter))
    }

    func openNewerChapter() async {
        guard let currentChapter else { return }
        await open(sequence.chapter(after: currentChapter))
    }

    func retryAppend() async {
        appendError = nil
        await appendNextChapter()
    }

    func toggleBookmark() async {
        guard let chapter = currentChapter else { return }
        do { isBookmarked = try await history.toggleBookmark(manga: manga, chapter: chapter) }
        catch { appendError = error.localizedDescription }
    }

    func suspend() async {
        guard let chapter = currentChapter else { return }
        session.suspend(chapter: chapter.id, pageIndex: currentPageIndex)
        sessionEvent = session.latestEvent
        await flush()
    }

    func resume() {
        session.resume()
    }

    func end() async {
        guard let chapter = currentChapter else { return }
        session.end(chapter: chapter.id, pageIndex: currentPageIndex)
        sessionEvent = session.latestEvent
        await flush()
        prefetcher.cancel()
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        await persistCurrentPosition()
    }

    private func open(_ chapter: Chapter?) async {
        guard let chapter else { return }
        await flush()
        if let loaded = loadedChapters.first(where: { $0.id == chapter.id }), let first = loaded.pages.first {
            currentPage = first.id
            currentAnchor = 0
            scrollRequest = ReaderScrollRequest(page: first.id, anchor: 0)
            isBookmarked = await history.progress(for: chapter.id)?.isBookmarked ?? false
            return
        }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let pages = try await reader.pages(for: chapter, manga: manga)
            guard let first = pages.first else { throw APIError.http(status: 404, message: "No pages found for \(chapter.name).") }
            loadedChapters = [LoadedReaderChapter(chapter: chapter, pages: pages)]
            currentPage = first.id
            currentAnchor = 0
            scrollRequest = ReaderScrollRequest(page: first.id, anchor: 0)
            isBookmarked = await history.progress(for: chapter.id)?.isBookmarked ?? false
            prefetcher.update(around: first, in: pages)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func appendNextChapter() async {
        guard !isAppending, let bottom = loadedChapters.last?.chapter,
              let next = sequence.chapter(after: bottom), !loadedChapters.contains(where: { $0.id == next.id }) else { return }
        isAppending = true
        appendError = nil
        defer { isAppending = false }
        do {
            let pages = try await reader.pages(for: next, manga: manga)
            guard !pages.isEmpty else { throw APIError.http(status: 404, message: "No pages found for \(next.name).") }
            loadedChapters.append(LoadedReaderChapter(chapter: next, pages: pages))
            if loadedChapters.count > retainedChapterLimit, let currentPage {
                loadedChapters.removeFirst(loadedChapters.count - retainedChapterLimit)
                scrollRequest = ReaderScrollRequest(page: currentPage, anchor: currentAnchor)
            }
        } catch {
            appendError = error.localizedDescription
        }
    }

    private func scheduleSave() {
        guard !incognito else { return }
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await self?.persistCurrentPosition()
        }
    }

    private func persistCurrentPosition() async {
        guard !incognito, let loaded = currentLoadedChapter, let currentPage else { return }
        let previous = await history.progress(for: loaded.id)
        let lastIndex = max(loaded.pages.count - 1, 0)
        let record = ReaderProgressRecord(
            manga: manga,
            chapter: loaded.chapter,
            pageIndex: min(max(currentPage.index, 0), lastIndex),
            intraPageAnchor: currentAnchor,
            totalPages: loaded.pages.count,
            activeReadingSeconds: (previous?.activeReadingSeconds ?? 0) + session.consumeActiveSeconds(),
            isRead: previous?.isRead == true || currentPage.index >= lastIndex,
            isBookmarked: isBookmarked,
            updatedAt: .now
        )
        try? await history.save(record, incognito: incognito)
    }
}
