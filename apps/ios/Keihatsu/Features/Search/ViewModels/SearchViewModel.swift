import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var sections: [SourceListingState] = []
    @Published private(set) var recentQueries: [String]
    private(set) var query = ""
    private var generation = UUID()
    private let repository: any CatalogueRepository
    private let defaults: UserDefaults

    init(repository: any CatalogueRepository, defaults: UserDefaults) {
        self.repository = repository
        self.defaults = defaults
        recentQueries = Array((defaults.stringArray(forKey: "keihatsu.search.recent") ?? []).prefix(5))
    }

    func remember(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        recentQueries.removeAll { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }
        recentQueries.insert(value, at: 0)
        recentQueries = Array(recentQueries.prefix(5))
        defaults.set(recentQueries, forKey: "keihatsu.search.recent")
    }

    func clearHistory() {
        recentQueries = []
        defaults.removeObject(forKey: "keihatsu.search.recent")
    }

    func search(_ text: String, sources: [Source], debounce: Bool = true) async {
        generation = UUID()
        let request = generation
        query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        sections = query.isEmpty ? [] : sources.map { SourceListingState(source: $0, isLoading: true) }
        guard !query.isEmpty else { return }
        if debounce {
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
        }
        guard generation == request, !Task.isCancelled else { return }
        remember(query)
        for start in stride(from: 0, to: sources.count, by: 3) {
            await withTaskGroup(of: Void.self) { group in
                for source in sources[start..<min(start + 3, sources.count)] {
                    group.addTask { await self.load(sourceID: source.id, generation: request, next: false) }
                }
            }
            guard generation == request, !Task.isCancelled else { return }
        }
    }

    func loadMore(_ sourceID: String) async { await load(sourceID: sourceID, generation: generation, next: true) }
    func retry(_ sourceID: String) async { await load(sourceID: sourceID, generation: generation, next: sections.first(where: { $0.id == sourceID })?.page ?? 0 > 0) }

    private func load(sourceID: String, generation request: UUID, next: Bool) async {
        guard request == generation, let index = sections.firstIndex(where: { $0.id == sourceID }) else { return }
        if next && (sections[index].isLoading || !sections[index].hasNextPage) { return }
        let page = next ? sections[index].page + 1 : 1
        let term = query
        sections[index].isLoading = true
        sections[index].error = nil
        do {
            let result = try await repository.mangas(sourceID: sourceID, listing: .search, page: page, query: term)
            guard request == generation, !Task.isCancelled else { return }
            var seen = Set<MangaIdentity>()
            let merged = (next ? sections[index].mangas : []) + result.mangas
            sections[index].mangas = merged.filter { seen.insert($0.id).inserted }
            sections[index].page = page
            sections[index].hasNextPage = result.hasNextPage
        } catch {
            guard request == generation, !Task.isCancelled else { return }
            sections[index].error = error.localizedDescription
        }
        if request == generation { sections[index].isLoading = false }
    }
}
