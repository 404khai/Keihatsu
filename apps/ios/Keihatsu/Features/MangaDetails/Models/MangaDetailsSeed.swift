import CryptoKit
import Foundation

nonisolated struct MangaDetailsSeed: Hashable, Sendable {
    let manga: Manga
    let coverAsset: String?
    let fallbackChapters: [Chapter]
    let transitionID: UUID
    var isLocalFixture: Bool { manga.id.sourceID == "local-preview" }

    init(manga: Manga, coverAsset: String? = nil, fallbackChapters: [Chapter] = [], transitionID: UUID? = nil) {
        self.manga = manga
        self.coverAsset = coverAsset
        self.fallbackChapters = fallbackChapters
        if let transitionID {
            self.transitionID = transitionID
        } else {
            let key = Data("\(manga.id.sourceID)\u{0}\(manga.id.mangaID)".utf8)
            let bytes = Array(SHA256.hash(data: key).prefix(16))
            self.transitionID = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
        }
    }

    init(item: ImageModel) {
        if let manga = item.manga {
            self.init(manga: manga, transitionID: item.id)
            return
        }
        let digest = SHA256.hash(data: Data(item.title.utf8)).map { String(format: "%02x", $0) }.joined()
        let id = MangaIdentity(sourceID: "local-preview", mangaID: String(digest.prefix(20)))
        let manga = Manga(
            id: id,
            title: item.title,
            url: nil,
            thumbnailURL: nil,
            description: item.summary,
            author: item.title == "Ordeal" ? "Brent Bristol" : nil,
            artist: item.title == "Ordeal" ? "Yong-Je Park" : nil,
            status: "Ongoing",
            genres: item.metadataLine.components(separatedBy: " • "),
            language: "en"
        )
        let numbers: [Double] = item.title == "Ordeal" ? [158, 156, 139] : Array((1...10).reversed()).map(Double.init)
        let chapters = numbers.map { number in
            Chapter(
                id: ChapterIdentity(manga: id, chapterID: "chapter-\(number.formatted(.number.precision(.fractionLength(0...1))))"),
                name: "Chapter \(number.formatted(.number.precision(.fractionLength(0...1))))",
                number: number,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -Int(number), to: .now),
                url: nil,
                scanlator: nil
            )
        }
        self.init(manga: manga, coverAsset: item.image, fallbackChapters: chapters, transitionID: item.id)
    }
}
