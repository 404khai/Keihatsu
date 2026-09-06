import Combine
import Foundation

nonisolated enum LibraryLayout: String, Codable, CaseIterable, Identifiable {
    case compact = "Compact grid", comfortable = "Comfortable grid", cover = "Cover grid", list = "List"
    var id: Self { self }
}
nonisolated enum LibrarySort: String, Codable, CaseIterable, Identifiable {
    case alphabetical = "Alphabetical", lastRead = "Last read", lastUpdated = "Last updated", unreadCount = "Unread count", totalChapters = "Total chapters", dateAdded = "Date added"
    var id: Self { self }
}
nonisolated struct LibraryOptions: Codable {
    var layout: LibraryLayout = .compact
    var columns = 3
    var showBadges = true
    var showCounts = true
    var downloaded = false
    var unread = false
    var started = false
    var bookmarked = false
    var completed = false
    var sort: LibrarySort = .lastRead
    var ascending = false

    func filtered(_ entries: [LibraryEntry], category: UUID?, query: String) -> [LibraryEntry] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return entries.filter { entry in
            (category.map { entry.categoryIDs.contains($0) } ?? entry.categoryIDs.isEmpty)
                && (!downloaded || entry.downloadedCount > 0) && (!unread || entry.unreadCount > 0)
                && (!started || entry.isStarted) && (!bookmarked || entry.isBookmarked) && (!completed || entry.isCompleted)
                && (term.isEmpty || [entry.item.title, entry.item.category, entry.item.metadataLine].contains { $0.localizedCaseInsensitiveContains(term) })
        }.sorted { a, b in
            let result: ComparisonResult
            switch sort {
            case .alphabetical: result = a.item.title.localizedStandardCompare(b.item.title)
            case .lastRead: result = (a.lastReadAt ?? .distantPast).compare(b.lastReadAt ?? .distantPast)
            case .lastUpdated: result = a.lastUpdatedAt.compare(b.lastUpdatedAt)
            case .dateAdded: result = a.dateAddedAt.compare(b.dateAddedAt)
            case .unreadCount: result = a.unreadCount == b.unreadCount ? .orderedSame : a.unreadCount < b.unreadCount ? .orderedAscending : .orderedDescending
            case .totalChapters: result = a.totalChapters == b.totalChapters ? .orderedSame : a.totalChapters < b.totalChapters ? .orderedAscending : .orderedDescending
            }
            if result == .orderedSame { return a.id.uuidString < b.id.uuidString }
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }
}

@MainActor
final class LibraryOptionsStore: ObservableObject {
    @Published var options: LibraryOptions { didSet { if let data = try? JSONEncoder().encode(options) { defaults.set(data, forKey: "keihatsu.library.options") } } }
    private let defaults: UserDefaults
    init(defaults: UserDefaults) {
        self.defaults = defaults
        options = defaults.data(forKey: "keihatsu.library.options").flatMap { try? JSONDecoder().decode(LibraryOptions.self, from: $0) } ?? LibraryOptions()
        options.columns = min(4, max(2, options.columns))
    }
}
