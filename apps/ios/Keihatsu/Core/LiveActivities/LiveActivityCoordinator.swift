import ActivityKit
import Combine
import Foundation

@MainActor
final class LiveActivityCoordinator: ObservableObject {
    @Published private(set) var authorizationEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    @Published private(set) var lastError: String?

    private var preferences = LocalUserPreferences.default
    private let isAvailable: Bool
    private var readingActivity: Activity<ReadingActivityAttributes>?
    private var downloadActivity: Activity<DownloadActivityAttributes>?
    private var incognitoActivity: Activity<IncognitoActivityAttributes>?
    private var readingSnapshot: ReadingLiveActivitySnapshot?
    private var readingUpdateTask: Task<Void, Never>?
    private var trackedDownloadIDs = Set<UUID>()
    private var downloadBatchID = UUID()
    private var dismissedReadingSessionIDs = Set<UUID>()
    private var dismissedDownloadBatchID: UUID?
    private var incognitoSessionID = UUID()
    private var dismissedIncognitoSessionID: UUID?
    private var authorizationTask: Task<Void, Never>?
    private var stateTasks: [String: Task<Void, Never>] = [:]

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
        guard isAvailable else {
            authorizationEnabled = false
            return
        }
        readingActivity = Activity<ReadingActivityAttributes>.activities.first
        downloadActivity = Activity<DownloadActivityAttributes>.activities.first
        incognitoActivity = Activity<IncognitoActivityAttributes>.activities.first
        if let incognitoActivity { incognitoSessionID = incognitoActivity.attributes.sessionID }
        if let readingActivity { monitor(readingActivity) }
        if let downloadActivity { monitor(downloadActivity) }
        if let incognitoActivity { monitor(incognitoActivity) }
        authorizationTask = Task { [weak self] in
            for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
                guard let self else { return }
                authorizationEnabled = enabled
                if !enabled { await endAll(immediate: true) }
            }
        }
    }

    deinit {
        authorizationTask?.cancel()
        readingUpdateTask?.cancel()
        for task in stateTasks.values { task.cancel() }
    }

    func configure(_ value: LocalUserPreferences) {
        let wasIncognito = preferences.incognitoModeEnabled
        preferences = value
        Task { [weak self] in
            guard let self else { return }
            if value.incognitoModeEnabled {
                await endReading(immediate: true)
                if !wasIncognito, incognitoActivity == nil {
                    incognitoSessionID = UUID()
                    dismissedIncognitoSessionID = nil
                }
                await startIncognito()
            } else {
                await endIncognito(immediate: true)
                if !value.readingLiveActivitiesEnabled {
                    await endReading(immediate: true)
                } else if let readingSnapshot {
                    updateReading(readingSnapshot)
                } else if readingActivity != nil {
                    await endReading(immediate: true)
                }
            }
            if !value.downloadLiveActivitiesEnabled {
                await endDownloads(immediate: true)
            }
        }
    }

    func startReading(_ snapshot: ReadingLiveActivitySnapshot) async {
        guard isAvailable,
              authorizationEnabled,
              preferences.readingLiveActivitiesEnabled,
              !preferences.incognitoModeEnabled,
              !dismissedReadingSessionIDs.contains(snapshot.sessionID) else { return }
        readingSnapshot = snapshot
        let state = readingState(snapshot, status: .reading)

        if readingActivity == nil {
            readingActivity = Activity<ReadingActivityAttributes>.activities.first {
                $0.attributes.sessionID == snapshot.sessionID
            }
            if let readingActivity { monitor(readingActivity) }
        }
        if let activity = readingActivity, activity.attributes.sessionID == snapshot.sessionID {
            await activity.update(ActivityContent(state: state, staleDate: .now.addingTimeInterval(5 * 60), relevanceScore: 0.9))
            lastError = nil
            return
        }
        await endReading(immediate: true)
        do {
            let attributes = ReadingActivityAttributes(
                sessionID: snapshot.sessionID
            )
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: .now.addingTimeInterval(5 * 60), relevanceScore: 0.9),
                pushType: nil
            )
            readingActivity = activity
            monitor(activity)
            lastError = nil
            // The system may reserve the Dynamic Island for other foreground UI while
            // Keihatsu is open. `activityState` and `Activity.activities` remain the
            // source of truth; the app must not draw an imitation Island.
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateReading(_ snapshot: ReadingLiveActivitySnapshot) {
        readingSnapshot = snapshot
        readingUpdateTask?.cancel()
        readingUpdateTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled, let self,
                  preferences.readingLiveActivitiesEnabled,
                  !preferences.incognitoModeEnabled else { return }
            if let activity = readingActivity,
               activity.attributes.sessionID == snapshot.sessionID {
                let state = readingState(snapshot, status: .reading)
                await activity.update(ActivityContent(state: state, staleDate: .now.addingTimeInterval(5 * 60), relevanceScore: 0.9))
            } else {
                // Page/title/identity data comes from the loaded local reader model.
                // Retrying here recovers a missed start without requiring the network.
                await startReading(snapshot)
            }
        }
    }

    func pauseReading(_ snapshot: ReadingLiveActivitySnapshot) async {
        readingUpdateTask?.cancel()
        readingSnapshot = snapshot
        guard let activity = readingActivity, activity.attributes.sessionID == snapshot.sessionID else { return }
        let state = readingState(snapshot, status: .paused)
        await activity.end(
            ActivityContent(state: state, staleDate: nil, relevanceScore: 0.8),
            dismissalPolicy: .after(.now.addingTimeInterval(15 * 60))
        )
        readingActivity = nil
    }

    func endReading(immediate: Bool = false) async {
        readingUpdateTask?.cancel()
        guard let activity = readingActivity else {
            readingSnapshot = nil
            return
        }
        let snapshot = readingSnapshot
        let finalState = snapshot.map { readingState($0, status: .finished) }
        await activity.end(
            finalState.map { ActivityContent(state: $0, staleDate: nil, relevanceScore: 0.5) },
            dismissalPolicy: immediate ? .immediate : .after(.now.addingTimeInterval(15 * 60))
        )
        readingActivity = nil
        readingSnapshot = nil
    }

    func syncDownloads(records: [ChapterDownloadRecord], isGloballyPaused: Bool) async {
        guard isAvailable, authorizationEnabled, preferences.downloadLiveActivitiesEnabled else {
            await endDownloads(immediate: true)
            return
        }
        let unfinished = records.filter { $0.status != .completed }
        if downloadActivity == nil, unfinished.isEmpty {
            trackedDownloadIDs.removeAll()
            dismissedDownloadBatchID = nil
            return
        }
        if trackedDownloadIDs.isEmpty {
            trackedDownloadIDs = Set(unfinished.map(\.id))
            downloadBatchID = UUID()
        }
        guard let projection = DownloadLiveActivityProjection.make(
            records: records,
            trackedRecordIDs: trackedDownloadIDs,
            batchID: downloadBatchID,
            isGloballyPaused: isGloballyPaused,
            showsDetails: preferences.showLiveActivityMangaDetails
        ) else {
            await endDownloads(immediate: true)
            return
        }
        trackedDownloadIDs = projection.trackedRecordIDs
        let state = downloadState(projection)

        if let activity = downloadActivity {
            if projection.hasUnfinishedWork, projection.status.isEligibleForLiveUpdates {
                await activity.update(ActivityContent(state: state, staleDate: .now.addingTimeInterval(10 * 60), relevanceScore: 0.7))
            } else {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil, relevanceScore: 0.6),
                    dismissalPolicy: projection.hasUnfinishedWork ? .after(.now.addingTimeInterval(5 * 60)) : .after(.now.addingTimeInterval(15 * 60))
                )
                downloadActivity = nil
                trackedDownloadIDs.removeAll()
                dismissedDownloadBatchID = nil
            }
            return
        }

        guard projection.hasUnfinishedWork,
              projection.status.isEligibleForLiveUpdates,
              dismissedDownloadBatchID != projection.batchID else { return }
        do {
            let activity = try Activity.request(
                attributes: DownloadActivityAttributes(batchID: projection.batchID),
                content: ActivityContent(state: state, staleDate: .now.addingTimeInterval(10 * 60), relevanceScore: 0.7),
                pushType: nil
            )
            downloadActivity = activity
            monitor(activity)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func endDownloads(immediate: Bool = false) async {
        if let activity = downloadActivity {
            await activity.end(nil, dismissalPolicy: immediate ? .immediate : .default)
        }
        downloadActivity = nil
        trackedDownloadIDs.removeAll()
        dismissedDownloadBatchID = nil
    }

    func startIncognito() async {
        guard isAvailable,
              authorizationEnabled,
              preferences.incognitoModeEnabled,
              dismissedIncognitoSessionID != incognitoSessionID else { return }
        let state = IncognitoActivityAttributes.ContentState(enabledAt: .now, updatedAt: .now)
        if let activity = incognitoActivity {
            await activity.update(ActivityContent(state: state, staleDate: nil, relevanceScore: 1))
            return
        }
        do {
            let activity = try Activity.request(
                attributes: IncognitoActivityAttributes(sessionID: incognitoSessionID),
                content: ActivityContent(state: state, staleDate: nil, relevanceScore: 1),
                pushType: nil
            )
            incognitoActivity = activity
            monitor(activity)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func endIncognito(immediate: Bool = true) async {
        if let activity = incognitoActivity {
            await activity.end(nil, dismissalPolicy: immediate ? .immediate : .default)
        }
        incognitoActivity = nil
        dismissedIncognitoSessionID = nil
    }

    func endAll(immediate: Bool) async {
        await endReading(immediate: immediate)
        await endDownloads(immediate: immediate)
        await endIncognito(immediate: immediate)
    }

    private func readingState(
        _ snapshot: ReadingLiveActivitySnapshot,
        status: ReadingActivityStatus
    ) -> ReadingActivityAttributes.ContentState {
        let showsDetails = preferences.showLiveActivityMangaDetails
        return ReadingActivityAttributes.ContentState(
            mangaTitle: (showsDetails ? snapshot.manga.title : "Manga reading session").liveActivityLimited(to: 120),
            chapterName: (showsDetails ? snapshot.chapter.name : "Keihatsu").liveActivityLimited(to: 80),
            sourceID: snapshot.manga.id.sourceID,
            mangaID: snapshot.manga.id.mangaID,
            chapterID: snapshot.chapter.id.chapterID,
            currentPage: snapshot.displayedPage,
            totalPages: max(snapshot.totalPages, 1),
            status: status,
            updatedAt: .now
        )
    }

    private func downloadState(_ projection: DownloadLiveActivityProjection) -> DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(
            mangaTitle: projection.mangaTitle.liveActivityLimited(to: 120),
            chapterName: projection.chapterName.liveActivityLimited(to: 80),
            completedChapters: projection.completedChapters,
            totalChapters: projection.totalChapters,
            progress: projection.progress,
            status: projection.status,
            updatedAt: .now
        )
    }

    private func monitor(_ activity: Activity<ReadingActivityAttributes>) {
        stateTasks[activity.id]?.cancel()
        stateTasks[activity.id] = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard let self else { return }
                if state == .dismissed || state == .ended {
                    if activity.id == readingActivity?.id {
                        if state == .dismissed { dismissedReadingSessionIDs.insert(activity.attributes.sessionID) }
                        readingActivity = nil
                    }
                    stateTasks[activity.id] = nil
                    return
                }
            }
        }
    }

    private func monitor(_ activity: Activity<DownloadActivityAttributes>) {
        stateTasks[activity.id]?.cancel()
        stateTasks[activity.id] = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard let self else { return }
                if state == .dismissed || state == .ended {
                    if activity.id == downloadActivity?.id {
                        if state == .dismissed { dismissedDownloadBatchID = activity.attributes.batchID }
                        downloadActivity = nil
                        if state == .ended { trackedDownloadIDs.removeAll() }
                    }
                    stateTasks[activity.id] = nil
                    return
                }
            }
        }
    }

    private func monitor(_ activity: Activity<IncognitoActivityAttributes>) {
        stateTasks[activity.id]?.cancel()
        stateTasks[activity.id] = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard let self else { return }
                if state == .dismissed || state == .ended {
                    if activity.id == incognitoActivity?.id {
                        if state == .dismissed { dismissedIncognitoSessionID = activity.attributes.sessionID }
                        incognitoActivity = nil
                    }
                    stateTasks[activity.id] = nil
                    return
                }
            }
        }
    }
}

private extension DownloadActivityStatus {
    var isEligibleForLiveUpdates: Bool {
        switch self {
        case .queued, .resolving, .downloading, .packaging:
            true
        case .paused, .waitingForWiFi, .failed, .completed:
            false
        }
    }
}

private extension String {
    func liveActivityLimited(to maximumCount: Int) -> String {
        count <= maximumCount ? self : String(prefix(maximumCount - 1)) + "…"
    }
}
