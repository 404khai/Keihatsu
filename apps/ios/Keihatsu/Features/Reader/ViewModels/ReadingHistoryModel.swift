import Combine
import Foundation

@MainActor
final class ReadingHistoryModel: ObservableObject {
    @Published private(set) var entries: [ReaderProgressRecord] = []
    private let repository: any HistoryRepository

    init(repository: any HistoryRepository) {
        self.repository = repository
    }

    func refresh() async {
        entries = await repository.recentProgress()
    }

    func progress(for chapter: ChapterIdentity) async -> ReaderProgressRecord? {
        await repository.progress(for: chapter)
    }

    func save(_ progress: ReaderProgressRecord, incognito: Bool) async throws {
        guard !incognito else { return }
        try await repository.saveProgress(progress)
        await refresh()
    }

    func toggleBookmark(manga: Manga, chapter: Chapter) async throws -> Bool {
        let value = try await repository.toggleBookmark(manga: manga, chapter: chapter)
        await refresh()
        return value
    }
}
