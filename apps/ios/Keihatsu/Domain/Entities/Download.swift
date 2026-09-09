import Foundation

nonisolated struct DownloadIdentity: Hashable, Codable, Sendable {
    let sourceID: String
    let mangaID: String
    let chapterID: String

    init(sourceID: String, mangaID: String, chapterID: String) {
        self.sourceID = sourceID
        self.mangaID = mangaID
        self.chapterID = chapterID
    }

    init(chapter: ChapterIdentity) {
        sourceID = chapter.manga.sourceID
        mangaID = chapter.manga.mangaID
        chapterID = chapter.chapterID
    }
}

nonisolated struct ChapterDownloadRequest: Hashable, Codable, Sendable {
    let identity: DownloadIdentity
    let ownerID: String
    let extensionName: String
    let mangaTitle: String
    let chapterName: String
    let chapterNumber: Double
    let thumbnailURL: URL?
}

nonisolated enum DownloadStatus: String, Codable, Sendable {
    case queued
    case resolving
    case downloading
    case packaging
    case paused
    case waitingForWiFi
    case failed
    case completed

    var isActive: Bool {
        switch self {
        case .queued, .resolving, .downloading, .packaging: true
        case .paused, .waitingForWiFi, .failed, .completed: false
        }
    }
}

nonisolated struct DownloadPageRecord: Hashable, Codable, Sendable {
    let index: Int
    let remoteURL: URL
    let refererURL: URL?
    var stagedFilename: String?
    var byteCount: Int64 = 0
}

nonisolated struct ChapterDownloadRecord: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let request: ChapterDownloadRequest
    var status: DownloadStatus
    var pages: [DownloadPageRecord]
    var activePageIndex: Int?
    var activeTaskIdentifier: Int?
    var priority: Int
    var progress: Double
    var errorMessage: String?
    var archiveByteCount: Int64
    let createdAt: Date
    var updatedAt: Date

    var completedPageCount: Int { pages.filter { $0.stagedFilename != nil }.count }
    var pageCount: Int { pages.count }
}

nonisolated struct DownloadStorageSnapshot: Equatable, Sendable {
    var archiveCount: Int
    var byteCount: Int64

    static let empty = DownloadStorageSnapshot(archiveCount: 0, byteCount: 0)
}
