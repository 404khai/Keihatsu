import Combine
import Foundation

@MainActor
final class DownloadCoordinator: ObservableObject {
    @Published private(set) var records: [ChapterDownloadRecord] = []
    @Published private(set) var storage: DownloadStorageSnapshot = .empty
    @Published private(set) var isRestoring = true
    @Published private(set) var isGloballyPaused: Bool

    private let catalogue: any CatalogueRepository
    private let archiveStore: ChapterArchiveStore
    private let recordStore: DownloadRecordStore
    private let transfer: BackgroundDownloadSession
    private let configuration: APIConfiguration
    private let network: DownloadNetworkMonitor
    private let preferences: AppPreferencesStore
    private let defaults: UserDefaults
    private var ownerID = "guest"
    private var scheduling = false
    private var pageFractions: [UUID: Double] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let globalPauseKey = "keihatsu.downloads.globalPause"

    init(
        catalogue: any CatalogueRepository,
        archiveStore: ChapterArchiveStore,
        recordStore: DownloadRecordStore,
        transfer: BackgroundDownloadSession,
        configuration: APIConfiguration,
        network: DownloadNetworkMonitor,
        preferences: AppPreferencesStore,
        defaults: UserDefaults = .standard
    ) {
        self.catalogue = catalogue
        self.archiveStore = archiveStore
        self.recordStore = recordStore
        self.transfer = transfer
        self.configuration = configuration
        self.network = network
        self.preferences = preferences
        self.defaults = defaults
        isGloballyPaused = defaults.bool(forKey: globalPauseKey)

        transfer.setEventHandler { [weak self] event in
            Task { @MainActor [weak self] in await self?.handle(event) }
        }
        network.$connection
            .removeDuplicates()
            .sink { [weak self] _ in self?.networkDidChange() }
            .store(in: &cancellables)
        preferences.$preferences
            .map(\.downloadOnWiFiOnly)
            .removeDuplicates()
            .sink { [weak self] _ in self?.networkDidChange() }
            .store(in: &cancellables)
        Task { await restore() }
    }

    var visibleRecords: [ChapterDownloadRecord] {
        records.filter { $0.request.ownerID == ownerID }.sorted { $0.priority < $1.priority }
    }

    var activeRecords: [ChapterDownloadRecord] { visibleRecords.filter { $0.status != .completed } }
    var completedRecords: [ChapterDownloadRecord] { visibleRecords.filter { $0.status == .completed } }

    func setOwner(_ value: String?) {
        let next = value ?? "guest"
        guard next != ownerID else { return }
        for index in records.indices where records[index].request.ownerID == ownerID {
            if let task = records[index].activeTaskIdentifier { transfer.cancel(taskIdentifier: task) }
            if records[index].status.isActive {
                records[index].status = .paused
                records[index].activeTaskIdentifier = nil
                records[index].activePageIndex = nil
            }
        }
        ownerID = next
        persist()
        objectWillChange.send()
        schedule()
    }

    func status(for chapter: ChapterIdentity) -> DownloadStatus? {
        visibleRecords.first { $0.request.identity == DownloadIdentity(chapter: chapter) }?.status
    }

    func isDownloaded(_ chapter: ChapterIdentity) -> Bool {
        status(for: chapter) == .completed
    }

    func downloadedCount(for manga: MangaIdentity) -> Int {
        completedRecords.filter { $0.request.identity.sourceID == manga.sourceID && $0.request.identity.mangaID == manga.mangaID }.count
    }

    func enqueue(manga: Manga, chapters: [Chapter], extensionName: String? = nil) {
        guard !chapters.isEmpty else { return }
        var nextPriority = (records.map(\.priority).max() ?? -1) + 1
        let orderedChapters = chapters.sorted {
            if $0.number == $1.number {
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return $0.number < $1.number
        }
        for chapter in orderedChapters {
            let identity = DownloadIdentity(chapter: chapter.id)
            if let index = records.firstIndex(where: { $0.request.ownerID == ownerID && $0.request.identity == identity }) {
                if records[index].status == .failed || records[index].status == .paused || records[index].status == .waitingForWiFi {
                    records[index].status = .queued
                    records[index].errorMessage = nil
                    records[index].updatedAt = .now
                }
                continue
            }
            let request = ChapterDownloadRequest(
                identity: identity,
                ownerID: ownerID,
                extensionName: extensionName ?? manga.id.sourceID,
                mangaTitle: manga.title,
                chapterName: chapter.name,
                chapterNumber: chapter.number,
                thumbnailURL: manga.thumbnailURL
            )
            records.append(ChapterDownloadRecord(
                id: UUID(), request: request, status: .queued, pages: [], activePageIndex: nil,
                activeTaskIdentifier: nil, priority: nextPriority, progress: 0, errorMessage: nil,
                archiveByteCount: 0, createdAt: .now, updatedAt: .now
            ))
            nextPriority += 1
        }
        persist()
        schedule()
    }

    func toggleGlobalPause() {
        isGloballyPaused.toggle()
        defaults.set(isGloballyPaused, forKey: globalPauseKey)
        if isGloballyPaused {
            for index in records.indices where records[index].request.ownerID == ownerID && records[index].status.isActive {
                if let task = records[index].activeTaskIdentifier { transfer.pause(taskIdentifier: task) }
                records[index].status = .paused
                records[index].activeTaskIdentifier = nil
                records[index].activePageIndex = nil
            }
            persist()
        } else {
            for index in records.indices where records[index].request.ownerID == ownerID && records[index].status == .paused {
                records[index].status = .queued
            }
            persist()
            schedule()
        }
    }

    func pause(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }), records[index].request.ownerID == ownerID else { return }
        if let task = records[index].activeTaskIdentifier { transfer.pause(taskIdentifier: task) }
        records[index].status = .paused
        records[index].activeTaskIdentifier = nil
        records[index].activePageIndex = nil
        records[index].updatedAt = .now
        persist()
        schedule()
    }

    func resume(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }), records[index].request.ownerID == ownerID else { return }
        records[index].status = .queued
        records[index].errorMessage = nil
        records[index].updatedAt = .now
        persist()
        schedule()
    }

    func move(in extensionName: String, from offsets: IndexSet, to destination: Int) {
        var values = activeRecords.filter { $0.request.extensionName == extensionName }
        let prioritySlots = values.map(\.priority).sorted()
        guard offsets.allSatisfy(values.indices.contains) else { return }
        let moving = offsets.sorted().map { values[$0] }
        for offset in offsets.sorted(by: >) { values.remove(at: offset) }
        let adjustedDestination = destination - offsets.filter { $0 < destination }.count
        values.insert(contentsOf: moving, at: min(max(adjustedDestination, 0), values.count))
        for (offset, value) in values.enumerated() {
            if let index = records.firstIndex(where: { $0.id == value.id }) {
                records[index].priority = prioritySlots[offset]
            }
        }
        persist()
        schedule()
    }

    func cancelDownloads(for manga: MangaIdentity) async {
        let matches = records.filter {
            $0.request.ownerID == ownerID
                && $0.status != .completed
                && $0.request.identity.sourceID == manga.sourceID
                && $0.request.identity.mangaID == manga.mangaID
        }
        guard !matches.isEmpty else { return }
        let ids = Set(matches.map(\.id))
        for record in matches {
            if let task = record.activeTaskIdentifier { transfer.cancel(taskIdentifier: task) }
            try? await archiveStore.discardStaging(recordID: record.id)
        }
        records.removeAll { ids.contains($0.id) }
        persist()
        await refreshStorage()
        schedule()
    }

    func moveToFront(_ id: UUID) {
        guard let record = records.first(where: { $0.id == id }), record.request.ownerID == ownerID else { return }
        let first = activeRecords.map(\.priority).min() ?? 0
        for index in records.indices where records[index].request.ownerID == ownerID && records[index].status != .completed {
            records[index].priority += 1
        }
        if let index = records.firstIndex(where: { $0.id == id }) { records[index].priority = first }
        persist()
        schedule()
    }

    func remove(_ id: UUID, deleteArchive: Bool = true) async {
        guard let index = records.firstIndex(where: { $0.id == id }), records[index].request.ownerID == ownerID else { return }
        let record = records.remove(at: index)
        if let task = record.activeTaskIdentifier { transfer.cancel(taskIdentifier: task) }
        try? await archiveStore.discardStaging(recordID: record.id)
        if deleteArchive { try? await archiveStore.delete(record.request.identity) }
        persist()
        await refreshStorage()
        schedule()
    }

    func retry(_ id: UUID) { resume(id) }

    func refreshStorage() async {
        var missing = Set<UUID>()
        for record in records where record.status == .completed {
            if !(await archiveStore.contains(record.request.identity)) { missing.insert(record.id) }
        }
        if !missing.isEmpty {
            records.removeAll { missing.contains($0.id) }
            persist()
        }
        storage = await archiveStore.storageSnapshot()
    }

    func exportURL(for record: ChapterDownloadRecord) async -> URL {
        await archiveStore.archiveURL(for: record.request.identity)
    }

    func changeDownloadDirectory(to url: URL) async throws {
        try await archiveStore.changeDownloadsRoot(to: url)
        await refreshStorage()
    }

    private func restore() async {
        records = await recordStore.load()
        let tasks = await transfer.taskDescriptions()
        let connectedIDs = Set(tasks.keys)
        for index in records.indices {
            guard records[index].status != .completed else { continue }
            if let task = records[index].activeTaskIdentifier, connectedIDs.contains(task) {
                records[index].status = .downloading
            } else if records[index].status.isActive {
                records[index].status = isGloballyPaused ? .paused : .queued
                records[index].activeTaskIdentifier = nil
                records[index].activePageIndex = nil
            }
        }
        isRestoring = false
        persist()
        await refreshStorage()
        schedule()
    }

    private func schedule() {
        guard !isRestoring, !isGloballyPaused, !scheduling else { return }
        scheduling = true
        Task { [weak self] in
            guard let self else { return }
            await self.scheduleEligibleSources()
            self.scheduling = false
        }
    }

    private func scheduleEligibleSources() async {
        guard network.connection != .offline else {
            markEligible(.waitingForWiFi, message: "Waiting for a network connection.")
            return
        }
        if preferences.preferences.downloadOnWiFiOnly && network.connection == .cellular {
            markEligible(.waitingForWiFi, message: "Waiting for Wi-Fi.")
            return
        }
        for index in records.indices where records[index].request.ownerID == ownerID && records[index].status == .waitingForWiFi {
            records[index].status = .queued
            records[index].errorMessage = nil
        }
        let busySources = Set(records.filter { $0.request.ownerID == ownerID && $0.activeTaskIdentifier != nil }.map(\.request.identity.sourceID))
        let queuedSources = Set(records.filter { $0.request.ownerID == ownerID && $0.status == .queued }.map(\.request.identity.sourceID))
        for source in queuedSources.subtracting(busySources) {
            guard let record = records.filter({ $0.request.ownerID == ownerID && $0.status == .queued && $0.request.identity.sourceID == source }).min(by: { $0.priority < $1.priority }) else { continue }
            await prepare(record.id)
        }
        persist()
    }

    private func prepare(_ id: UUID) async {
        guard var index = records.firstIndex(where: { $0.id == id }) else { return }
        if records[index].pages.isEmpty {
            records[index].status = .resolving
            records[index].updatedAt = .now
            persist()
            do {
                let identity = records[index].request.identity
                let chapter = ChapterIdentity(manga: MangaIdentity(sourceID: identity.sourceID, mangaID: identity.mangaID), chapterID: identity.chapterID)
                let pages = try await catalogue.pages(for: chapter).sorted { $0.id.index < $1.id.index }
                guard !pages.isEmpty else { throw APIError.http(status: 404, message: "This chapter has no downloadable pages.") }
                guard let current = records.firstIndex(where: { $0.id == id }) else { return }
                index = current
                records[index].pages = pages.map { DownloadPageRecord(index: $0.id.index, remoteURL: $0.imageURL, refererURL: $0.refererURL) }
                records[index].status = .queued
            } catch {
                fail(id, message: error.localizedDescription)
                return
            }
        }
        guard let current = records.firstIndex(where: { $0.id == id }) else { return }
        index = current
        if let next = records[index].pages.first(where: { $0.stagedFilename == nil }) {
            do {
                var request = try ImagePipeline.request(url: next.remoteURL, referer: next.refererURL, configuration: configuration)
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148", forHTTPHeaderField: "User-Agent")
                if request.url == next.remoteURL, let referer = next.refererURL { request.setValue(referer.absoluteString, forHTTPHeaderField: "Referer") }
                let description = "\(id.uuidString):\(next.index)"
                let taskID = transfer.start(request: request, description: description)
                records[index].status = .downloading
                records[index].activePageIndex = next.index
                records[index].activeTaskIdentifier = taskID
                records[index].errorMessage = nil
                records[index].updatedAt = .now
            } catch { fail(id, message: error.localizedDescription) }
        } else {
            await package(id)
        }
    }

    private func package(_ id: UUID) async {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].status = .packaging
        records[index].progress = 1
        records[index].updatedAt = .now
        persist()
        do {
            let url = try await archiveStore.package(record: records[index])
            guard await archiveStore.contains(records[index].request.identity) else { throw ChapterArchiveStore.ArchiveError.invalidArchive }
            let bytes = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            guard let current = records.firstIndex(where: { $0.id == id }) else { return }
            records[current].status = .completed
            records[current].archiveByteCount = bytes
            records[current].activePageIndex = nil
            records[current].activeTaskIdentifier = nil
            records[current].errorMessage = nil
            records[current].updatedAt = .now
            persist()
            await refreshStorage()
        } catch { fail(id, message: error.localizedDescription) }
        schedule()
    }

    private func handle(_ event: BackgroundDownloadEvent) async {
        switch event {
        case .progress(let taskID, let written, let expected):
            guard let index = records.firstIndex(where: { $0.activeTaskIdentifier == taskID }) else { return }
            let fraction = expected > 0 ? min(max(Double(written) / Double(expected), 0), 1) : 0
            pageFractions[records[index].id] = fraction
            records[index].progress = (Double(records[index].completedPageCount) + fraction) / Double(max(records[index].pageCount, 1))
        case .completed(let taskID, let incoming, let response):
            guard let index = records.firstIndex(where: { $0.activeTaskIdentifier == taskID }),
                  let pageIndex = records[index].activePageIndex,
                  let pageOffset = records[index].pages.firstIndex(where: { $0.index == pageIndex }) else {
                try? FileManager.default.removeItem(at: incoming)
                return
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                try? FileManager.default.removeItem(at: incoming)
                fail(records[index].id, message: "Image request failed (\(http.statusCode)).")
                return
            }
            do {
                let destination = try await archiveStore.storeStagedDownload(incoming, recordID: records[index].id, pageIndex: pageIndex)
                records[index].pages[pageOffset].stagedFilename = destination.lastPathComponent
                records[index].pages[pageOffset].byteCount = Int64((try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                records[index].activeTaskIdentifier = nil
                records[index].activePageIndex = nil
                records[index].progress = Double(records[index].completedPageCount) / Double(max(records[index].pageCount, 1))
                records[index].status = .queued
                records[index].updatedAt = .now
                pageFractions[records[index].id] = nil
                persist()
                schedule()
            } catch { fail(records[index].id, message: error.localizedDescription) }
        case .paused(let taskID, _):
            guard let index = records.firstIndex(where: { $0.activeTaskIdentifier == taskID }) else { return }
            records[index].activeTaskIdentifier = nil
            records[index].activePageIndex = nil
            if records[index].status != .waitingForWiFi { records[index].status = .paused }
            persist()
            schedule()
        case .failed(let taskID, let message):
            guard let record = records.first(where: { $0.activeTaskIdentifier == taskID }) else { return }
            fail(record.id, message: message)
        }
    }

    private func fail(_ id: UUID, message: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].status = .failed
        records[index].activeTaskIdentifier = nil
        records[index].activePageIndex = nil
        records[index].errorMessage = message
        records[index].updatedAt = .now
        persist()
        schedule()
    }

    private func networkDidChange() {
        if network.connection == .offline || (preferences.preferences.downloadOnWiFiOnly && network.connection == .cellular) {
            for index in records.indices where records[index].request.ownerID == ownerID && records[index].status.isActive {
                if let task = records[index].activeTaskIdentifier { transfer.pause(taskIdentifier: task) }
                records[index].status = .waitingForWiFi
                records[index].errorMessage = network.connection == .offline ? "Waiting for a network connection." : "Waiting for Wi-Fi."
            }
            persist()
        } else { schedule() }
    }

    private func markEligible(_ status: DownloadStatus, message: String) {
        for index in records.indices where records[index].request.ownerID == ownerID && records[index].status == .queued {
            records[index].status = status
            records[index].errorMessage = message
        }
        persist()
    }

    private func persist() {
        let snapshot = records
        Task { try? await recordStore.save(snapshot) }
    }
}
