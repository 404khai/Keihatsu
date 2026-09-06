import Foundation

actor LocalHistoryRepository: HistoryRepository {
    private let progressStore: ReaderProgressStore
    private let detailsStore: MangaDetailsStore

    init(progressStore: ReaderProgressStore, detailsStore: MangaDetailsStore) {
        self.progressStore = progressStore
        self.detailsStore = detailsStore
    }

    func progress(for chapter: ChapterIdentity) async -> ReaderProgressRecord? {
        if let progress = await progressStore.progress(for: chapter) { return progress }
        guard let detail = await detailsStore.record(for: chapter.manga),
              let value = detail.chapters.first(where: { $0.id == chapter }) else { return nil }
        let state = detail.state(for: chapter)
        return ReaderProgressRecord(
            manga: detail.manga,
            chapter: value,
            pageIndex: state.pageIndex ?? 0,
            intraPageAnchor: 0,
            totalPages: 0,
            activeReadingSeconds: 0,
            isRead: state.isRead,
            isBookmarked: state.isBookmarked,
            updatedAt: state.lastReadAt ?? detail.updatedAt
        )
    }

    func recentProgress() async -> [ReaderProgressRecord] {
        await progressStore.recent()
    }

    func saveProgress(_ progress: ReaderProgressRecord) async throws {
        try await progressStore.save(progress)
        _ = try? await detailsStore.updateState(for: progress.chapter.id) { state in
            state.pageIndex = progress.pageIndex
            state.lastReadAt = progress.updatedAt
            state.isRead = progress.isRead
            state.isBookmarked = progress.isBookmarked
        }
    }

    func toggleBookmark(manga: Manga, chapter: Chapter) async throws -> Bool {
        let current = await progress(for: chapter.id)?.isBookmarked ?? false
        let bookmarked = !current
        try await progressStore.setBookmark(bookmarked, manga: manga, chapter: chapter)
        _ = try? await detailsStore.updateState(for: chapter.id) { $0.isBookmarked = bookmarked }
        return bookmarked
    }
}
