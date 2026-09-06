import Combine
import Foundation

@MainActor
final class CollectionStore: ObservableObject {
    @Published private(set) var snapshot = CollectionSnapshot(library: [], categories: [], history: [])
    @Published private(set) var error: String?
    private let repository: any CollectionRepository

    init(repository: any CollectionRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do { snapshot = try repository.load(); error = nil }
        catch { self.error = error.localizedDescription }
    }

    @discardableResult
    func saveCategory(id: UUID?, name: String) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.localizedCaseInsensitiveCompare("Default") != .orderedSame,
              !snapshot.categories.contains(where: { $0.id != id && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            error = "Choose a unique category name."
            return false
        }
        var value = snapshot
        if let id, let index = value.categories.firstIndex(where: { $0.id == id }) { value.categories[index].name = name }
        else { value.categories.append(LibraryCategory(id: UUID(), name: name)) }
        return persist(value)
    }

    func deleteCategory(_ id: UUID) {
        var value = snapshot
        value.categories.removeAll { $0.id == id }
        for index in value.library.indices { value.library[index].categoryIDs.remove(id) }
        _ = persist(value)
    }

    func assign(_ category: UUID, entry: UUID, included: Bool) {
        var value = snapshot
        guard let index = value.library.firstIndex(where: { $0.id == entry }) else { return }
        if included { value.library[index].categoryIDs.insert(category) }
        else { value.library[index].categoryIDs.remove(category) }
        _ = persist(value)
    }

    func deleteHistory(_ ids: Set<UUID>) {
        var value = snapshot
        value.history.removeAll { ids.contains($0.id) }
        _ = persist(value)
    }

    func historySections(query: String, calendar: Calendar = .current, now: Date = Date()) -> [HistorySection] {
        let groups = Dictionary(grouping: snapshot.history, by: { calendar.startOfDay(for: $0.readAt) })
        return groups.keys.sorted(by: >).compactMap { day in
            let title = calendar.isDate(day, inSameDayAs: now) ? "Today" : day.formatted(date: .abbreviated, time: .omitted)
            let items = (groups[day] ?? []).sorted { $0.readAt > $1.readAt }.filter {
                query.isEmpty || [$0.title, $0.chapter, $0.time, title].contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
            return items.isEmpty ? nil : HistorySection(id: day, date: title, items: items)
        }
    }

    private func persist(_ value: CollectionSnapshot) -> Bool {
        do { try repository.save(value); snapshot = value; error = nil; return true }
        catch { self.error = error.localizedDescription; return false }
    }
}
