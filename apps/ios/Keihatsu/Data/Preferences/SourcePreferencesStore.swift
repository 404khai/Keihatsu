import Combine
import Foundation

@MainActor
final class SourcePreferencesStore: ObservableObject {
    @Published private(set) var sources: [Source] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var revision = 0
    private let repository: any CatalogueRepository
    private let defaults: UserDefaults
    private var enabled: [String: Bool]
    private var pinned: [String: Bool]
    private var loaded = false

    init(repository: any CatalogueRepository, defaults: UserDefaults) {
        self.repository = repository
        self.defaults = defaults
        enabled = defaults.dictionary(forKey: "keihatsu.sources.enabled") as? [String: Bool] ?? [:]
        pinned = defaults.dictionary(forKey: "keihatsu.sources.pinned") as? [String: Bool] ?? [:]
    }

    func isAvailable(_ source: Source) -> Bool { source.id.lowercased() == "manhuatop" }
    func isEnabled(_ source: Source) -> Bool { isAvailable(source) && (enabled[source.id] ?? true) }
    func isPinned(_ source: Source) -> Bool { pinned[source.id] ?? (source.id == "manhuatop") }
    var enabledSources: [Source] { sortedSources.filter(isEnabled) }
    var sortedSources: [Source] {
        sources.sorted { lhs, rhs in
            if isPinned(lhs) != isPinned(rhs) { return isPinned(lhs) }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    func setEnabled(_ value: Bool, source: Source) {
        guard isAvailable(source) else { return }
        enabled[source.id] = value
        defaults.set(enabled, forKey: "keihatsu.sources.enabled")
        revision += 1
    }

    func setPinned(_ value: Bool, source: Source) {
        pinned[source.id] = value
        defaults.set(pinned, forKey: "keihatsu.sources.pinned")
        revision += 1
    }

    func load(force: Bool = false) async {
        guard !isLoading, force || !loaded else { return }
        isLoading = true
        defer { isLoading = false }
        if sources.isEmpty, let cached = await repository.cachedSources() { sources = cached; revision += 1 }
        do {
            let result = try await repository.sources()
            try Task.checkCancellation()
            var seen = Set<String>()
            sources = result.filter { seen.insert($0.id).inserted }
            error = nil
            loaded = true
            revision += 1
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}
