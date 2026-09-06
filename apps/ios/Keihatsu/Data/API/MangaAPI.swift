import Foundation

nonisolated enum MangaAPI {
    static func details(_ id: MangaIdentity) -> APIRequest<MangaDTO> {
        APIRequest(path: ["sources", id.sourceID, "manga", id.mangaID])
    }

    static func chapters(_ id: MangaIdentity) -> APIRequest<[ChapterDTO]> {
        APIRequest(path: ["sources", id.sourceID, "manga", id.mangaID, "chapters"])
    }

    static func pages(_ id: ChapterIdentity) -> APIRequest<[ReaderPageDTO]> {
        APIRequest(path: ["sources", id.manga.sourceID, "chapters", id.chapterID, "pages"])
    }
}
