import CryptoKit
import Foundation

actor DefaultReaderRepository: ReaderRepository {
    private let catalogue: any CatalogueRepository
    private let bundle: Bundle
    private let localRoot: URL?

    init(catalogue: any CatalogueRepository, bundle: Bundle = .main, localRoot: URL? = nil) {
        self.catalogue = catalogue
        self.bundle = bundle
        self.localRoot = localRoot ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Keihatsu/Chapters", directoryHint: .isDirectory)
    }

    func pages(for chapter: Chapter, manga: Manga) async throws -> [ReaderPage] {
        let local = localPages(for: chapter)
        if !local.isEmpty { return local }

        let bundled = bundledPages(for: chapter, manga: manga)
        if !bundled.isEmpty { return bundled }

        guard manga.id.sourceID != "local-preview" else {
            throw APIError.http(status: 404, message: "Pages for \(chapter.name) aren’t available in this build.")
        }
        return try await catalogue.pages(for: chapter.id)
            .sorted { $0.id.index < $1.id.index }
    }

    private func localPages(for chapter: Chapter) -> [ReaderPage] {
        guard let localRoot else { return [] }
        let key = "\(chapter.id.manga.sourceID)\u{0}\(chapter.id.manga.mangaID)\u{0}\(chapter.id.chapterID)"
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        let directory = localRoot.appending(path: digest, directoryHint: .isDirectory)
        guard let values = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        return pageValues(values, chapter: chapter.id)
    }

    private func bundledPages(for chapter: Chapter, manga: Manga) -> [ReaderPage] {
        guard manga.id.sourceID == "local-preview", manga.title.localizedCaseInsensitiveContains("Ordeal") else { return [] }
        let number = Int(chapter.number.rounded(.towardZero))
        guard [139, 156, 158].contains(number), let root = bundle.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
        let prefix = "ordeal_ch\(number)_"
        let values = enumerator.compactMap { $0 as? URL }.filter { $0.lastPathComponent.hasPrefix(prefix) }
        return pageValues(values, chapter: chapter.id)
    }

    private func pageValues(_ values: [URL], chapter: ChapterIdentity) -> [ReaderPage] {
        values
            .filter { ["jpg", "jpeg", "png", "webp"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .enumerated()
            .map { index, url in ReaderPage(id: .init(chapter: chapter, index: index), imageURL: url, refererURL: nil) }
    }
}
