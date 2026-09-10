import Combine
import Foundation

nonisolated struct SourceListingState: Identifiable, Sendable {
    let source: Source
    var mangas: [Manga] = []
    var error: String?
    var isLoading = false
    var isCached = false
    var page = 0
    var hasNextPage = false
    var id: String { source.id }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var sections: [SourceListingState] = []
    @Published private(set) var isLoading = false
    private let repository: any CatalogueRepository
    private var generation = UUID()

    init(repository: any CatalogueRepository) { self.repository = repository }

    var mangas: [Manga] {
        var seen = Set<MangaIdentity>()
        return sections.flatMap(\.mangas).filter { seen.insert($0.id).inserted }
    }

    func load(sources: [Source]) async {
        let request = UUID()
        generation = request
        sections = sources.map { source in sections.first(where: { $0.id == source.id }) ?? SourceListingState(source: source) }
        isLoading = !sources.isEmpty
        defer { if generation == request { isLoading = false } }
        // At most three provider requests are in flight, even if availability expands later.
        for start in stride(from: 0, to: sources.count, by: 3) {
            let batch = Array(sources[start..<min(start + 3, sources.count)])
            await withTaskGroup(of: SourceListingState.self) { group in
                for source in batch {
                    if let cached = await repository.cachedMangas(sourceID: source.id, listing: .latest, page: 1, query: nil), generation == request {
                        replace(SourceListingState(source: source, mangas: cached.mangas, isCached: true))
                    }
                    let old = sections.first { $0.id == source.id }
                    group.addTask { [repository] in
                        do {
                            let page = try await repository.mangas(sourceID: source.id, listing: .latest, page: 1, query: nil)
                            return SourceListingState(source: source, mangas: page.mangas, page: 1, hasNextPage: page.hasNextPage)
                        } catch {
                            return SourceListingState(source: source, mangas: old?.mangas ?? [], error: error.localizedDescription, isCached: !(old?.mangas.isEmpty ?? true))
                        }
                    }
                }
                for await result in group {
                    guard !Task.isCancelled, generation == request else { continue }
                    replace(result)
                }
            }
            guard !Task.isCancelled, generation == request else { return }
        }
    }

    private func replace(_ value: SourceListingState) {
        if let index = sections.firstIndex(where: { $0.id == value.id }) { sections[index] = value }
    }
}
