import Foundation

@MainActor
protocol CollectionMutationHandling: AnyObject {
    func handleCollectionMutation(_ intent: CollectionMutationIntent, snapshot: CollectionSnapshot)
}

nonisolated enum CollectionMutationIntent: Sendable {
    case createCategory(UUID, String)
    case renameCategory(UUID, String)
    case deleteCategory(UUID)
    case assignCategories(UUID, Set<UUID>)
    case addLibrary(UUID, Manga, Set<UUID>)
    case removeLibrary(UUID)
}

@MainActor
final class AccountDataCoordinator: CollectionMutationHandling {
    private let libraryAPI: LibraryAPI
    private let categoriesAPI: CategoriesAPI
    private let historyAPI: HistoryAPI
    private let userAPI: any UserServicing
    private let store: AccountDataStore
    private let collections: CollectionStore
    private let historyRepository: any HistoryRepository
    private let readingHistory: ReadingHistoryModel
    private let libraryOptions: LibraryOptionsStore
    private let sources: SourcePreferencesStore
    private let syncStatus: SyncQueueStore

    private var currentUserID: String?
    private var token: String?
    private var generation = UUID()
    private var bootstrapTask: Task<Void, Never>?
    private var processing = false
    private var lastSyncedProgress: [ChapterIdentity: Double] = [:]

    init(
        libraryAPI: LibraryAPI,
        categoriesAPI: CategoriesAPI,
        historyAPI: HistoryAPI,
        userAPI: any UserServicing,
        store: AccountDataStore,
        collections: CollectionStore,
        historyRepository: any HistoryRepository,
        readingHistory: ReadingHistoryModel,
        libraryOptions: LibraryOptionsStore,
        sources: SourcePreferencesStore,
        syncStatus: SyncQueueStore
    ) {
        self.libraryAPI = libraryAPI
        self.categoriesAPI = categoriesAPI
        self.historyAPI = historyAPI
        self.userAPI = userAPI
        self.store = store
        self.collections = collections
        self.historyRepository = historyRepository
        self.readingHistory = readingHistory
        self.libraryOptions = libraryOptions
        self.sources = sources
        self.syncStatus = syncStatus
    }

    func attachCached(userID: String) async {
        currentUserID = userID
        if let cached = await store.collections(ownerUserID: userID) {
            collections.applyAccountSnapshot(cached.snapshot)
        } else {
            collections.applyAccountSnapshot(CollectionSnapshot(library: [], categories: [], history: []))
        }
        await refreshSyncStatus(userID: userID)
    }

    func attach(userID: String, token: String) async {
        generation = UUID()
        let requestGeneration = generation
        currentUserID = userID
        self.token = token
        await attachCached(userID: userID)
        bootstrapTask?.cancel()
        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.bootstrap(userID: userID, token: token, generation: requestGeneration)
        }
        bootstrapTask = task
        await task.value
    }

    func detach(userID: String?) async {
        generation = UUID()
        bootstrapTask?.cancel()
        bootstrapTask = nil
        token = nil
        currentUserID = nil
        processing = false
        lastSyncedProgress.removeAll()
        collections.restoreGuestSnapshot()
        syncStatus.replace(with: [], lastSyncedAt: nil)
    }

    func sync(progress: ReaderProgressRecord) async {
        guard let owner = currentUserID, token != nil else { return }
        let previous = lastSyncedProgress[progress.id] ?? 0
        let delta = max(progress.activeReadingSeconds - previous, 0)
        lastSyncedProgress[progress.id] = progress.activeReadingSeconds
        try? await store.enqueue(
            ownerUserID: owner,
            mutation: .syncHistory(
                operationID: UUID(), progress: progress,
                readingTimeDeltaMilliseconds: Int((delta * 1_000).rounded())
            )
        )
        await processOutbox()
    }

    func deleteHistory(_ manga: MangaIdentity) async {
        guard let owner = currentUserID else { return }
        let operationID = UUID(), date = Date()
        try? await store.enqueue(ownerUserID: owner, mutation: .deleteHistory(operationID: operationID, manga: manga, deletedAt: date))
        try? await historyRepository.deleteProgress(for: manga)
        await readingHistory.refresh()
        await processOutbox()
    }

    func queuePreferences(_ value: SyncedUserPreferences) {
        guard let owner = currentUserID else { return }
        Task {
            try? await store.enqueue(ownerUserID: owner, mutation: .updatePreferences(value))
            await processOutbox()
        }
    }

    func handleCollectionMutation(_ intent: CollectionMutationIntent, snapshot: CollectionSnapshot) {
        guard let owner = currentUserID else { return }
        Task {
            var data = await store.collections(ownerUserID: owner) ?? AccountCollectionData(ownerUserID: owner, library: [], categories: [])
            let prior = data
            reconcileLocal(snapshot: snapshot, data: &data)
            let mutation: AccountMutation
            switch intent {
            case .createCategory(let id, let name): mutation = .createCategory(localID: id, name: name)
            case .renameCategory(let id, let name): mutation = .renameCategory(localID: id, name: name)
            case .deleteCategory(let id):
                mutation = .deleteCategory(localID: id, serverID: prior.categories.first(where: { $0.id == id })?.serverID)
            case .assignCategories(let id, let categories): mutation = .setCategories(libraryLocalID: id, categoryLocalIDs: categories)
            case .addLibrary(let id, let manga, let categories): mutation = .addLibrary(localID: id, manga: manga, categoryIDs: categories)
            case .removeLibrary(let id):
                mutation = .removeLibrary(localID: id, serverID: prior.library.first(where: { $0.id == id })?.serverID)
            }
            try? await store.save(data)
            try? await store.enqueue(ownerUserID: owner, mutation: mutation)
            await refreshSyncStatus(userID: owner)
            await processOutbox()
        }
    }

    private func bootstrap(userID: String, token: String, generation: UUID) async {
        do {
            async let categories = categoriesAPI.all(token: token)
            async let library = libraryAPI.all(token: token)
            async let history = historyAPI.all(token: token)
            async let preferences = userAPI.preferences(token: token)
            let values = try await (categories, library, history, preferences)
            guard generation == self.generation, currentUserID == userID else { return }
            let cached = await store.collections(ownerUserID: userID)
            let categoryRecords = values.0.map { remote -> AccountCategoryRecord in
                let localID = cached?.categories.first(where: { $0.serverID == remote.id })?.id ?? UUID()
                return AccountCategoryRecord(id: localID, serverID: remote.id, name: remote.name)
            }
            let categoryIDs = Dictionary(uniqueKeysWithValues: categoryRecords.compactMap { record in record.serverID.map { ($0, record.id) } })
            let libraryRecords = values.1.map { remote -> AccountLibraryRecord in
                let localID = cached?.library.first(where: {
                    $0.serverID == remote.id || $0.manga.id == MangaIdentity(sourceID: remote.sourceId, mangaID: remote.mangaId)
                })?.id
                return remote.domain(categoryIDs: categoryIDs, localID: localID)
            }
            let pending = await store.outbox(ownerUserID: userID)
            var merged = AccountCollectionData(ownerUserID: userID, library: libraryRecords, categories: categoryRecords)
            if !pending.isEmpty, let cached {
                mergeCachedPending(cached, into: &merged)
            }
            try await store.save(merged)
            collections.applyAccountSnapshot(merged.snapshot)
            apply(values.3)
            for remote in values.2 {
                if let deleted = remote.deletedAt.flatMap(APIDate.parse) {
                    let manga = MangaIdentity(sourceID: remote.sourceId, mangaID: remote.mangaId)
                    if let local = await historyRepository.recentProgress().first(where: { $0.manga.id == manga }), local.updatedAt <= deleted {
                        try? await historyRepository.deleteProgress(for: manga)
                    }
                } else if let progress = remote.progress {
                    let local = await historyRepository.progress(for: progress.id)
                    if local == nil || progress.updatedAt > local!.updatedAt {
                        try? await historyRepository.saveProgress(progress)
                    }
                }
            }
            await readingHistory.refresh()
            await processOutbox()
        } catch is CancellationError {
        } catch {
            guard generation == self.generation else { return }
            syncStatus.setError(error.localizedDescription)
        }
    }

    private func processOutbox() async {
        guard !processing, let owner = currentUserID, let token else { return }
        processing = true
        defer { processing = false }
        let requestGeneration = generation
        for record in await store.outbox(ownerUserID: owner) {
            guard currentUserID == owner, generation == requestGeneration else { return }
            if record.state == .terminalFailure || record.state == .conflict || record.state == .authenticationRequired { continue }
            do {
                try await store.updateOutbox(id: record.id, state: .syncing)
                try await execute(record.mutation, owner: owner, token: token)
                try await store.acknowledgeOutbox(id: record.id)
                syncStatus.markSynced()
            } catch {
                let state = failureState(error)
                try? await store.updateOutbox(id: record.id, state: state, error: error.localizedDescription)
                if state == .authenticationRequired { break }
                if state == .retryableFailure { break }
            }
            await refreshSyncStatus(userID: owner)
        }
        await refreshSyncStatus(userID: owner)
    }

    private func execute(_ mutation: AccountMutation, owner: String, token: String) async throws {
        var data = await store.collections(ownerUserID: owner) ?? AccountCollectionData(ownerUserID: owner, library: [], categories: [])
        switch mutation {
        case .addLibrary(let localID, let manga, let categoryIDs):
            let remote = try await libraryAPI.add(manga, token: token)
            if let index = data.library.firstIndex(where: { $0.id == localID }) { data.library[index].serverID = remote.id }
            try await store.save(data)
            if !categoryIDs.isEmpty {
                try await setCategories(libraryID: localID, categoryIDs: categoryIDs, data: &data, token: token)
            }
        case .removeLibrary(_, let serverID):
            if let serverID { try await libraryAPI.remove(serverID: serverID, token: token) }
        case .updateLibrary(let localID, let unread, let started, let bookmarked, let completed):
            guard let serverID = data.library.first(where: { $0.id == localID })?.serverID else { throw SyncDependencyError.unresolvedIdentity }
            try await libraryAPI.update(serverID: serverID, flags: (unread, started, bookmarked, completed), token: token)
        case .createCategory(let localID, let name):
            let remote = try await categoriesAPI.create(name: name, token: token)
            if let index = data.categories.firstIndex(where: { $0.id == localID }) { data.categories[index].serverID = remote.id }
            try await store.save(data)
        case .renameCategory(let localID, let name):
            guard let serverID = data.categories.first(where: { $0.id == localID })?.serverID else { throw SyncDependencyError.unresolvedIdentity }
            _ = try await categoriesAPI.rename(serverID: serverID, name: name, token: token)
        case .deleteCategory(_, let serverID):
            if let serverID { try await categoriesAPI.remove(serverID: serverID, token: token) }
        case .setCategories(let libraryID, let categoryIDs):
            try await setCategories(libraryID: libraryID, categoryIDs: categoryIDs, data: &data, token: token)
        case .syncHistory(let operationID, let progress, let milliseconds):
            try await historyAPI.sync(operationID: operationID, progress: progress, readingTimeDeltaMilliseconds: milliseconds, token: token)
        case .deleteHistory(let operationID, let manga, let date):
            try await historyAPI.remove(manga: manga, operationID: operationID, deletedAt: date, token: token)
        case .updatePreferences(let preferences):
            _ = try await userAPI.updatePreferences(preferences, token: token)
        }
    }

    private func setCategories(libraryID: UUID, categoryIDs: Set<UUID>, data: inout AccountCollectionData, token: String) async throws {
        guard let serverID = data.library.first(where: { $0.id == libraryID })?.serverID else { throw SyncDependencyError.unresolvedIdentity }
        let serverCategories = try categoryIDs.map { localID -> String in
            guard let serverID = data.categories.first(where: { $0.id == localID })?.serverID else { throw SyncDependencyError.unresolvedIdentity }
            return serverID
        }
        _ = try await libraryAPI.setCategories(serverID: serverID, categoryIDs: serverCategories.sorted(), token: token)
    }

    private func reconcileLocal(snapshot: CollectionSnapshot, data: inout AccountCollectionData) {
        data.categories = snapshot.categories.map { category in
            AccountCategoryRecord(id: category.id, serverID: data.categories.first(where: { $0.id == category.id })?.serverID, name: category.name)
        }
        data.library = snapshot.library.map { entry in
            let existing = data.library.first(where: { $0.id == entry.id })
            return AccountLibraryRecord(
                id: entry.id, serverID: existing?.serverID, manga: entry.item.manga ?? existing?.manga ?? Manga(
                    id: .init(sourceID: "unknown", mangaID: entry.id.uuidString), title: entry.item.title,
                    url: nil, thumbnailURL: nil, description: nil, author: nil, artist: nil,
                    status: nil, genres: [], language: nil
                ), categoryIDs: entry.categoryIDs, downloadedCount: entry.downloadedCount,
                unreadCount: entry.unreadCount, totalChapters: entry.totalChapters,
                isStarted: entry.isStarted, isBookmarked: entry.isBookmarked,
                isCompleted: entry.isCompleted, lastReadAt: entry.lastReadAt,
                lastUpdatedAt: entry.lastUpdatedAt, dateAddedAt: entry.dateAddedAt
            )
        }
    }

    private func mergeCachedPending(_ cached: AccountCollectionData, into remote: inout AccountCollectionData) {
        for category in cached.categories where !remote.categories.contains(where: { $0.id == category.id || ($0.serverID != nil && $0.serverID == category.serverID) }) {
            remote.categories.append(category)
        }
        for library in cached.library {
            if let index = remote.library.firstIndex(where: { $0.id == library.id || $0.manga.id == library.manga.id }) {
                remote.library[index] = library
            } else {
                remote.library.append(library)
            }
        }
    }

    private func apply(_ preferences: SyncedUserPreferences) {
        libraryOptions.apply(preferences)
        sources.apply(preferences.sourcePreferences)
    }

    private func failureState(_ error: Error) -> AccountMutationState {
        if case APIError.http(let status, _) = error {
            if status == 401 { return .authenticationRequired }
            if status == 409 { return .conflict }
            if (400..<500).contains(status) { return .terminalFailure }
            return .retryableFailure
        }
        if error is SyncDependencyError { return .retryableFailure }
        if error is URLError { return .retryableFailure }
        return .terminalFailure
    }

    private func refreshSyncStatus(userID: String) async {
        let records = await store.outbox(ownerUserID: userID)
        syncStatus.replace(
            with: records.map { record in
                SyncOperation(
                    id: record.id,
                    kind: record.mutation.kind,
                    summary: record.mutation.summary,
                    status: record.state.displayStatus,
                    queuedAt: record.createdAt
                )
            },
            lastSyncedAt: syncStatus.lastSyncedAt
        )
    }
}

nonisolated enum SyncDependencyError: LocalizedError, Sendable {
    case unresolvedIdentity
    var errorDescription: String? { "Waiting for a dependent account record to sync." }
}

private extension AccountMutation {
    var kind: SyncOperationKind {
        switch self {
        case .addLibrary, .removeLibrary, .updateLibrary, .createCategory, .renameCategory, .deleteCategory, .setCategories: .library
        case .syncHistory, .deleteHistory: .history
        case .updatePreferences: .preferences
        }
    }

    var summary: String {
        switch self {
        case .addLibrary(_, let manga, _): "Add \(manga.title)"
        case .removeLibrary: "Remove library title"
        case .updateLibrary: "Update library title"
        case .createCategory(_, let name): "Create \(name)"
        case .renameCategory(_, let name): "Rename category to \(name)"
        case .deleteCategory: "Delete category"
        case .setCategories: "Update categories"
        case .syncHistory(_, let progress, _): "Sync \(progress.chapter.name)"
        case .deleteHistory: "Delete reading history"
        case .updatePreferences: "Update display preferences"
        }
    }
}

private extension AccountMutationState {
    var displayStatus: SyncOperationStatus {
        switch self {
        case .queued: .queued
        case .syncing: .syncing
        case .retryableFailure, .conflict, .authenticationRequired, .terminalFailure: .failed
        }
    }
}
