import Foundation

nonisolated struct HistoryAPI: Sendable {
    private struct SyncBody: Encodable {
        let operationId: UUID
        let mangaId: String
        let sourceId: String
        let chapterId: String
        let pageNumber: Int
        let lastReadAt: String
        let title: String
        let thumbnailUrl: String?
        let author: String?
        let chapterName: String
        let chapterNumber: Double
        let readingTimeMs: Int
        let isBookmarked: Bool
        let isRead: Bool
    }
    private let client: APIClient
    init(client: APIClient) { self.client = client }

    func all(token: String) async throws -> [HistoryEntryDTO] {
        var page = 1
        let limit = 100
        var result: [HistoryEntryDTO] = []
        while true {
            let request = APIRequest<[HistoryEntryDTO]>(
                path: ["history"],
                query: [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "include_deleted", value: "true")],
                requiresAuthentication: true
            )
            let values = try await client.send(request, bearerToken: token)
            result += values
            guard values.count == limit else { return result }
            page += 1
        }
    }

    func sync(operationID: UUID, progress: ReaderProgressRecord, readingTimeDeltaMilliseconds: Int, token: String) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let body = try JSONEncoder().encode(SyncBody(
            operationId: operationID,
            mangaId: progress.manga.id.mangaID, sourceId: progress.manga.id.sourceID,
            chapterId: progress.chapter.id.chapterID, pageNumber: progress.pageIndex,
            lastReadAt: formatter.string(from: progress.updatedAt), title: progress.manga.title,
            thumbnailUrl: progress.manga.thumbnailURL?.absoluteString, author: progress.manga.author,
            chapterName: progress.chapter.name, chapterNumber: progress.chapter.number,
            readingTimeMs: max(readingTimeDeltaMilliseconds, 0), isBookmarked: progress.isBookmarked,
            isRead: progress.isRead
        ))
        let _: HistoryEntryDTO = try await client.send(
            APIRequest<HistoryEntryDTO>(path: ["history", "sync"], method: .post, body: body, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func remove(manga: MangaIdentity, operationID: UUID, deletedAt: Date, token: String) async throws {
        let formatter = ISO8601DateFormatter()
        let request = APIRequest<EmptyAPIResponse>(
            path: ["history", manga.sourceID, manga.mangaID],
            query: [URLQueryItem(name: "operation_id", value: operationID.uuidString), URLQueryItem(name: "deleted_at", value: formatter.string(from: deletedAt))],
            method: .delete,
            requiresAuthentication: true
        )
        let _: EmptyAPIResponse = try await client.send(request, bearerToken: token)
    }
}
