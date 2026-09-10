import Foundation

nonisolated struct ReadingLiveActivitySnapshot: Equatable, Sendable {
    let sessionID: UUID
    let manga: Manga
    let chapter: Chapter
    let pageIndex: Int
    let totalPages: Int

    var displayedPage: Int {
        min(max(pageIndex + 1, 1), max(totalPages, 1))
    }
}

nonisolated struct DownloadLiveActivityProjection: Equatable, Sendable {
    let batchID: UUID
    let trackedRecordIDs: Set<UUID>
    let mangaTitle: String
    let chapterName: String
    let completedChapters: Int
    let totalChapters: Int
    let progress: Double
    let status: DownloadActivityStatus
    let hasUnfinishedWork: Bool

    static func make(
        records: [ChapterDownloadRecord],
        trackedRecordIDs: Set<UUID>,
        batchID: UUID,
        isGloballyPaused: Bool,
        showsDetails: Bool
    ) -> DownloadLiveActivityProjection? {
        let visible = records.sorted { $0.priority < $1.priority }
        var tracked = trackedRecordIDs
        tracked.formUnion(visible.filter { $0.status != .completed }.map(\.id))
        let batch = visible.filter { tracked.contains($0.id) }
        guard !batch.isEmpty else { return nil }

        let unfinished = batch.filter { $0.status != .completed }
        let current = unfinished.first ?? batch.last!
        let completed = batch.count - unfinished.count
        let average = batch.reduce(0.0) { sum, record in
            sum + (record.status == .completed ? 1 : min(max(record.progress, 0), 1))
        } / Double(batch.count)

        let status: DownloadActivityStatus
        if unfinished.isEmpty {
            status = .completed
        } else if isGloballyPaused {
            status = .paused
        } else if let active = unfinished.first(where: { $0.status == .downloading }) {
            status = .downloading
            return build(active, tracked, completed, batch.count, average, status, batchID, showsDetails, true)
        } else if let packaging = unfinished.first(where: { $0.status == .packaging }) {
            status = .packaging
            return build(packaging, tracked, completed, batch.count, average, status, batchID, showsDetails, true)
        } else if unfinished.allSatisfy({ $0.status == .failed }) {
            status = .failed
        } else if unfinished.allSatisfy({ $0.status == .waitingForWiFi }) {
            status = .waitingForWiFi
        } else if unfinished.allSatisfy({ $0.status == .paused }) {
            status = .paused
        } else if unfinished.contains(where: { $0.status == .resolving }) {
            status = .resolving
        } else {
            status = .queued
        }

        return build(current, tracked, completed, batch.count, average, status, batchID, showsDetails, !unfinished.isEmpty)
    }

    private static func build(
        _ current: ChapterDownloadRecord,
        _ tracked: Set<UUID>,
        _ completed: Int,
        _ total: Int,
        _ progress: Double,
        _ status: DownloadActivityStatus,
        _ batchID: UUID,
        _ showsDetails: Bool,
        _ hasUnfinishedWork: Bool
    ) -> DownloadLiveActivityProjection {
        DownloadLiveActivityProjection(
            batchID: batchID,
            trackedRecordIDs: tracked,
            mangaTitle: showsDetails ? current.request.mangaTitle : "Chapter downloads",
            chapterName: showsDetails ? current.request.chapterName : "Keihatsu",
            completedChapters: completed,
            totalChapters: total,
            progress: progress,
            status: status,
            hasUnfinishedWork: hasUnfinishedWork
        )
    }
}
