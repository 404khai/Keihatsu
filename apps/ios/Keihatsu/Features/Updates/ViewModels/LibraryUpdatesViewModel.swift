import Combine
import Foundation

@MainActor
final class LibraryUpdatesViewModel: ObservableObject {
    @Published private(set) var items: [LibraryUpdateItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var errorMessage: String?
    @Published var filter: LibraryUpdateFilter = .all

    private let repository: any MangaDetailsRepository

    init(repository: any MangaDetailsRepository) {
        self.repository = repository
    }

    func load(
        entries: [LibraryEntry],
        history: [ReaderProgressRecord],
        forceRefresh: Bool
    ) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let historyByChapter = Dictionary(uniqueKeysWithValues: history.map { ($0.chapter.id, $0) })
        let repository = repository
        let results = await withTaskGroup(of: [LibraryUpdateItem].self) { group in
            for entry in entries {
                group.addTask {
                    let seed = MangaDetailsSeed(item: entry.item)
                    if seed.isLocalFixture {
                        return seed.fallbackChapters.map { chapter in
                            let progress = historyByChapter[chapter.id]
                            return LibraryUpdateItem(
                                manga: seed.manga,
                                chapter: chapter,
                                state: ChapterReadingState(
                                    isRead: progress?.isRead ?? false,
                                    isBookmarked: progress?.isBookmarked ?? false,
                                    lastReadAt: progress?.updatedAt,
                                    pageIndex: progress?.pageIndex
                                ),
                                coverAsset: seed.coverAsset
                            )
                        }
                    }

                    if forceRefresh { _ = try? await repository.refreshChapters(for: seed.manga.id) }
                    guard let record = await repository.cachedRecord(for: seed.manga.id) else { return [] }
                    let manga = record.manga.title.isEmpty ? seed.manga : record.manga
                    return record.chapters.map { chapter in
                        var state = record.state(for: chapter.id)
                        if let progress = historyByChapter[chapter.id] {
                            state.isRead = progress.isRead
                            state.isBookmarked = progress.isBookmarked
                            state.lastReadAt = progress.updatedAt
                            state.pageIndex = progress.pageIndex
                        }
                        return LibraryUpdateItem(
                            manga: manga,
                            chapter: chapter,
                            state: state,
                            coverAsset: seed.coverAsset
                        )
                    }
                }
            }
            var values: [LibraryUpdateItem] = []
            for await result in group { values.append(contentsOf: result) }
            return values
        }

        items = results
            .filter { $0.uploadedAt != nil }
            .sorted { ($0.uploadedAt ?? .distantPast) > ($1.uploadedAt ?? .distantPast) }
        lastUpdatedAt = .now
        if entries.isEmpty {
            errorMessage = "Add titles to your library to see chapter updates."
        } else if items.isEmpty {
            errorMessage = forceRefresh ? "No dated chapters were returned by your sources." : nil
        }
    }

    func groups(isDownloaded: (ChapterIdentity) -> Bool, calendar: Calendar = .current) -> [LibraryUpdateDay] {
        let visible = items.filter { item in
            switch filter {
            case .all: true
            case .unread: !item.state.isRead
            case .downloaded: isDownloaded(item.chapter.id)
            }
        }
        let grouped = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.uploadedAt ?? .distantPast) }
        return grouped.keys.sorted(by: >).map { day in
            LibraryUpdateDay(
                date: day,
                items: (grouped[day] ?? []).sorted { $0.chapter.number > $1.chapter.number }
            )
        }
    }

    /// Connected sources currently expose chapter history but not a calendar
    /// endpoint. The most common recent upload weekday is the local estimate.
    func scheduledItems(on date: Date, calendar: Calendar = .current) -> [LibraryUpdateItem] {
        let grouped = Dictionary(grouping: items, by: { $0.manga.id })
        return grouped.values.compactMap { values in
            let recent = values.prefix(12)
            let weekdays = Dictionary(grouping: recent) {
                calendar.component(.weekday, from: $0.uploadedAt ?? .distantPast)
            }
            guard let predicted = weekdays.max(by: { lhs, rhs in
                if lhs.value.count == rhs.value.count {
                    return lhs.key != calendar.component(.weekday, from: values[0].uploadedAt ?? .distantPast)
                }
                return lhs.value.count < rhs.value.count
            })?.key,
                  predicted == calendar.component(.weekday, from: date) else { return nil }
            return values[0]
        }
        .sorted { $0.manga.title.localizedStandardCompare($1.manga.title) == .orderedAscending }
    }
}
