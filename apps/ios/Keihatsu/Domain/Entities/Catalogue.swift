import Foundation

nonisolated struct Manga: Identifiable, Hashable, Sendable {
    let id: MangaIdentity
    let title: String
    let url: URL?
    let thumbnailURL: URL?
    let description: String?
    let author: String?
    let artist: String?
    let status: String?
    let genres: [String]
    let language: String?
}

nonisolated struct Chapter: Identifiable, Hashable, Sendable {
    let id: ChapterIdentity
    let name: String
    let number: Double
    let uploadedAt: Date?
    let url: URL?
    let scanlator: String?
}

nonisolated struct ReaderPage: Identifiable, Hashable, Sendable {
    struct ID: Hashable, Sendable {
        let chapter: ChapterIdentity
        let index: Int
    }

    let id: ID
    let imageURL: URL
    let refererURL: URL?
}

nonisolated struct Source: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let language: String
    let baseURL: URL?
    let iconURL: URL?
    let version: Int
}

nonisolated struct MangaPage: Sendable {
    let mangas: [Manga]
    let hasNextPage: Bool
}
