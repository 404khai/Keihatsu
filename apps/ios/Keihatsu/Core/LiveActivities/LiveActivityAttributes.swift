import ActivityKit
import Foundation

nonisolated struct ReadingActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        let mangaTitle: String
        let chapterName: String
        let sourceID: String
        let mangaID: String
        let chapterID: String
        let currentPage: Int
        let totalPages: Int
        let status: ReadingActivityStatus
        let updatedAt: Date

        var progress: Double {
            guard totalPages > 0 else { return 0 }
            return min(max(Double(currentPage) / Double(totalPages), 0), 1)
        }
    }

    let sessionID: UUID
}

nonisolated enum ReadingActivityStatus: String, Codable, Hashable, Sendable {
    case reading
    case paused
    case finished
}

nonisolated struct DownloadActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        let mangaTitle: String
        let chapterName: String
        let completedChapters: Int
        let totalChapters: Int
        let progress: Double
        let status: DownloadActivityStatus
        let updatedAt: Date
    }

    let batchID: UUID
}

nonisolated struct IncognitoActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        let enabledAt: Date
        let updatedAt: Date
        let isReading: Bool?
        let currentPage: Int?
        let totalPages: Int?

        var pagePosition: String? {
            guard isReading == true,
                  let currentPage, let totalPages,
                  currentPage > 0, totalPages > 0,
                  currentPage <= totalPages else { return nil }
            return "\(currentPage) of \(totalPages)"
        }
    }

    let sessionID: UUID
}

nonisolated enum DownloadActivityStatus: String, Codable, Hashable, Sendable {
    case queued
    case resolving
    case downloading
    case packaging
    case paused
    case waitingForWiFi
    case failed
    case completed

    var label: String {
        switch self {
        case .queued: "Queued"
        case .resolving: "Preparing"
        case .downloading: "Downloading"
        case .packaging: "Saving chapter"
        case .paused: "Paused"
        case .waitingForWiFi: "Waiting for Wi-Fi"
        case .failed: "Download failed"
        case .completed: "Download complete"
        }
    }
}

nonisolated enum LiveActivityLink {
    static func downloads() -> URL? {
        URL(string: "keihatsu://downloads")
    }

    static func reader(attributes: ReadingActivityAttributes, state: ReadingActivityAttributes.ContentState) -> URL? {
        var components = URLComponents()
        components.scheme = "keihatsu"
        components.host = "reader"
        components.queryItems = [
            URLQueryItem(name: "source", value: state.sourceID),
            URLQueryItem(name: "manga", value: state.mangaID),
            URLQueryItem(name: "chapter", value: state.chapterID),
            URLQueryItem(name: "page", value: String(max(state.currentPage - 1, 0)))
        ]
        return components.url
    }

    static func privacy() -> URL? {
        URL(string: "keihatsu://privacy")
    }
}
