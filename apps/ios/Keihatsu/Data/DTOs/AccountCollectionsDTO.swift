import Foundation

nonisolated struct LibraryEntryDTO: Decodable, Sendable {
    let id: String
    let mangaId: String
    let sourceId: String
    let title: String
    let thumbnailUrl: String?
    let author: String?
    let language: String?
    let unreadCount: Int?
    let downloadedCount: Int?
    let totalChapters: Int?
    let isUnread: Bool?
    let isStarted: Bool?
    let isBookmarked: Bool?
    let isCompleted: Bool?
    let lastReadAt: String?
    let lastUpdatedAt: String?
    let dateAddedAt: String?
    let categories: [CategoryDTO]?

    func domain(categoryIDs: [String: UUID], localID: UUID? = nil) -> AccountLibraryRecord {
        let manga = Manga(
            id: .init(sourceID: sourceId, mangaID: mangaId), title: title, url: nil,
            thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)), description: nil,
            author: author, artist: nil, status: nil, genres: [], language: language
        )
        return AccountLibraryRecord(
            id: localID ?? ImageModel(manga: manga).id, serverID: id, manga: manga,
            categoryIDs: Set((categories ?? []).compactMap { categoryIDs[$0.id] }),
            downloadedCount: downloadedCount ?? 0, unreadCount: unreadCount ?? 0,
            totalChapters: totalChapters ?? 0, isStarted: isStarted ?? false,
            isBookmarked: isBookmarked ?? true, isCompleted: isCompleted ?? false,
            lastReadAt: lastReadAt.flatMap(APIDate.parse),
            lastUpdatedAt: lastUpdatedAt.flatMap(APIDate.parse) ?? .distantPast,
            dateAddedAt: dateAddedAt.flatMap(APIDate.parse) ?? .distantPast
        )
    }
}

nonisolated struct CategoryDTO: Decodable, Sendable {
    let id: String
    let name: String
}

nonisolated struct HistoryEntryDTO: Decodable, Sendable {
    let id: String
    let mangaId: String
    let sourceId: String
    let chapterId: String
    let pageNumber: Int?
    let lastReadAt: String
    let isBookmarked: Bool?
    let isRead: Bool?
    let title: String?
    let thumbnailUrl: String?
    let author: String?
    let chapterName: String?
    let chapterNumber: Double?
    let deletedAt: String?

    var progress: ReaderProgressRecord? {
        guard deletedAt == nil else { return nil }
        let mangaID = MangaIdentity(sourceID: sourceId, mangaID: mangaId)
        let manga = Manga(
            id: mangaID, title: title?.nilIfBlank ?? mangaId, url: nil,
            thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)), description: nil,
            author: author, artist: nil, status: nil, genres: [], language: nil
        )
        let chapter = Chapter(
            id: .init(manga: mangaID, chapterID: chapterId),
            name: chapterName?.nilIfBlank ?? "Chapter", number: chapterNumber ?? 0,
            uploadedAt: nil, url: nil, scanlator: nil
        )
        return ReaderProgressRecord(
            manga: manga, chapter: chapter, pageIndex: max(pageNumber ?? 0, 0),
            intraPageAnchor: 0, totalPages: 0, activeReadingSeconds: 0,
            isRead: isRead ?? false, isBookmarked: isBookmarked ?? false,
            updatedAt: APIDate.parse(lastReadAt) ?? .distantPast
        )
    }
}

private extension String {
    nonisolated var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
