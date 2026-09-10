import Foundation

nonisolated struct SourceDTO: Decodable, Sendable {
    let id: String
    let name: String
    let lang: String
    let baseUrl: String
    let iconUrl: String?
    let versionId: Int

    func domain() -> Source {
        Source(id: id, name: name, language: lang, baseURL: URL(string: baseUrl), iconURL: iconUrl.flatMap(URL.init(string:)), version: versionId)
    }
}

nonisolated struct MangaDTO: Decodable, Sendable {
    let id: String
    let sourceId: String
    let title: String
    let url: String
    let thumbnailUrl: String
    let description: String?
    let author: String?
    let artist: String?
    let status: String?
    let genres: [String]?
    let lang: String?

    func domain() -> Manga {
        Manga(id: MangaIdentity(sourceID: sourceId, mangaID: id), title: title,
              url: url.isEmpty ? nil : URL(string: url), thumbnailURL: thumbnailUrl.isEmpty ? nil : URL(string: thumbnailUrl),
              description: description, author: author, artist: artist, status: status, genres: genres ?? [], language: lang)
    }
}

nonisolated struct MangaPageDTO: Decodable, Sendable {
    let mangas: [MangaDTO]
    let hasNextPage: Bool

    func domain() -> MangaPage {
        MangaPage(mangas: mangas.map { $0.domain() }, hasNextPage: hasNextPage)
    }
}

nonisolated struct ChapterDTO: Decodable, Sendable {
    let id: String
    let name: String
    let chapterNumber: Double
    let dateUpload: Double
    let url: String
    let scanlator: String?

    func domain(manga: MangaIdentity) -> Chapter {
        Chapter(id: ChapterIdentity(manga: manga, chapterID: id), name: name, number: chapterNumber,
                uploadedAt: dateUpload > 0 ? Date(timeIntervalSince1970: dateUpload / 1_000) : nil,
                url: URL(string: url), scanlator: scanlator)
    }
}

nonisolated struct ReaderPageDTO: Decodable, Sendable {
    let index: Int
    let imageUrl: String
    let url: String

    func domain(chapter: ChapterIdentity) throws -> ReaderPage {
        guard index >= 0, let imageURL = URL(string: imageUrl),
              ["http", "https"].contains(imageURL.scheme?.lowercased() ?? ""), imageURL.host != nil else {
            throw APIError.decoding
        }
        return ReaderPage(id: .init(chapter: chapter, index: index), imageURL: imageURL, refererURL: URL(string: url))
    }
}
