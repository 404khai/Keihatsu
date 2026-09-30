import Combine
import Foundation

@MainActor
final class ReadingHistoryModel: ObservableObject {
    @Published private(set) var entries: [ReaderProgressRecord] = []
    @Published private(set) var chapterEntries: [ReaderProgressRecord] = []
    private let repository: any HistoryRepository
    weak var syncCoordinator: AccountDataCoordinator?

    init(repository: any HistoryRepository) {
        self.repository = repository
    }

    func refresh() async {
        entries = await repository.recentProgress()
        chapterEntries = await repository.allProgress()
    }

    func refreshFromAccount() async {
        await refresh()
        await syncCoordinator?.refreshReadingHistory()
    }

    func progress(for chapter: ChapterIdentity) async -> ReaderProgressRecord? {
        await repository.progress(for: chapter)
    }

    func save(_ progress: ReaderProgressRecord, incognito: Bool) async throws {
        guard !incognito else { return }
        try await repository.saveProgress(progress)
        await syncCoordinator?.sync(progress: progress)
        await refresh()
    }

    func toggleBookmark(manga: Manga, chapter: Chapter) async throws -> Bool {
        let value = try await repository.toggleBookmark(manga: manga, chapter: chapter)
        if let progress = await repository.progress(for: chapter.id) { await syncCoordinator?.sync(progress: progress) }
        await refresh()
        return value
    }


    func delete(_ manga: MangaIdentity) async {
        await delete([manga])
    }

    func delete(_ mangas: Set<MangaIdentity>) async {
        guard !mangas.isEmpty else { return }
        if let syncCoordinator {
            await syncCoordinator.deleteHistory(mangas)
        } else {
            for manga in mangas {
                try? await repository.deleteProgress(for: manga)
            }
            await refresh()
        }
    }
}
