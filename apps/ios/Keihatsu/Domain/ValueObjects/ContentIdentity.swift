import Foundation

nonisolated struct MangaIdentity: Hashable, Codable, Sendable {
    let sourceID: String
    let mangaID: String
}

nonisolated struct ChapterIdentity: Hashable, Codable, Sendable {
    let manga: MangaIdentity
    let chapterID: String
}

nonisolated struct ReaderLaunchContext: Hashable, Codable, Sendable {
    enum Origin: String, Codable, Sendable {
        case home, library, history, search, details
    }

    let chapter: ChapterIdentity
    let origin: Origin
    /// Zero-based, matching the history API. Nil means no saved position.
    let pageIndex: Int?
}
