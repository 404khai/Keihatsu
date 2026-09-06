import Combine
import Foundation

@MainActor
final class CollectionStore: ObservableObject {
    @Published private(set) var snapshot = CollectionSnapshot(library: [], categories: [], history: [])
    @Published private(set) var error: String?
    private let repository: any CollectionRepository
    private var guestSnapshot: CollectionSnapshot?
    weak var mutationHandler: (any CollectionMutationHandling)?
    private(set) var isAccountScoped = false

    init(repository: any CollectionRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        guard !isAccountScoped else { return }
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
        let intent: CollectionMutationIntent
        if let id, let index = value.categories.firstIndex(where: { $0.id == id }) {
            value.categories[index].name = name
            intent = .renameCategory(id, name)
        } else {
            let id = UUID()
            value.categories.append(LibraryCategory(id: id, name: name))
            intent = .createCategory(id, name)
        }
        let saved = persist(value)
        if saved, isAccountScoped { mutationHandler?.handleCollectionMutation(intent, snapshot: value) }
        return saved
    }

    func deleteCategory(_ id: UUID) {
        var value = snapshot
        value.categories.removeAll { $0.id == id }
        for index in value.library.indices { value.library[index].categoryIDs.remove(id) }
        if persist(value), isAccountScoped { mutationHandler?.handleCollectionMutation(.deleteCategory(id), snapshot: value) }
    }

    func assign(_ category: UUID, entry: UUID, included: Bool) {
        var value = snapshot
        guard let index = value.library.firstIndex(where: { $0.id == entry }) else { return }
        if included { value.library[index].categoryIDs.insert(category) }
        else { value.library[index].categoryIDs.remove(category) }
        if persist(value), isAccountScoped {
            mutationHandler?.handleCollectionMutation(.assignCategories(entry, value.library[index].categoryIDs), snapshot: value)
        }
    }

    func deleteHistory(_ ids: Set<UUID>) {
        var value = snapshot
        value.history.removeAll { ids.contains($0.id) }
        _ = persist(value)
    }

    @discardableResult
    func addToLibrary(_ manga: Manga, categoryIDs: Set<UUID>) -> Bool {
        guard !snapshot.library.contains(where: { $0.item.manga?.id == manga.id }) else { return true }
        var value = snapshot
        let item = ImageModel(manga: manga)
        value.library.append(LibraryEntry(
            item: item, categoryIDs: categoryIDs, downloadedCount: 0, unreadCount: 0,
            totalChapters: 0, isStarted: false, isBookmarked: true, isCompleted: false,
            lastReadAt: nil, lastUpdatedAt: .now, dateAddedAt: .now
        ))
        let saved = persist(value)
        if saved, isAccountScoped { mutationHandler?.handleCollectionMutation(.addLibrary(item.id, manga, categoryIDs), snapshot: value) }
        return saved
    }

    func removeFromLibrary(_ id: UUID) {
        var value = snapshot
        value.library.removeAll { $0.id == id }
        if persist(value), isAccountScoped { mutationHandler?.handleCollectionMutation(.removeLibrary(id), snapshot: value) }
    }

    func applyAccountSnapshot(_ value: CollectionSnapshot) {
        if !isAccountScoped { guestSnapshot = snapshot }
        isAccountScoped = true
        snapshot = value
        error = nil
    }

    func restoreGuestSnapshot() {
        isAccountScoped = false
        if let guestSnapshot {
            snapshot = guestSnapshot
            error = nil
        } else {
            reload()
        }
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
        if isAccountScoped {
            snapshot = value
            error = nil
            return true
        }
        do {
            try repository.save(value)
            guestSnapshot = value
            snapshot = value
            error = nil
            return true
        }
        catch { self.error = error.localizedDescription; return false }
    }
}
