import CryptoKit
import Foundation

actor MangaDetailsStore {
    private let directory: URL?
    private var memory: [MangaIdentity: MangaDetailsRecord] = [:]
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(namespace: String, directory: URL? = nil, persistToDisk: Bool = true) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        guard persistToDisk else {
            self.directory = nil
            return
        }
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let digest = SHA256.hash(data: Data(namespace.utf8)).map { String(format: "%02x", $0) }.joined()
        self.directory = base?.appending(path: "Keihatsu/MangaDetails/\(digest)", directoryHint: .isDirectory)
    }

    func record(for id: MangaIdentity) -> MangaDetailsRecord? {
        if let record = memory[id] { return record }
        guard let directory, let data = try? Data(contentsOf: fileURL(for: id, in: directory)),
              let record = try? decoder.decode(MangaDetailsRecord.self, from: data) else { return nil }
        memory[id] = record
        return record
    }

    @discardableResult
    func mergeMetadata(_ manga: Manga) throws -> MangaDetailsRecord {
        var value = record(for: manga.id) ?? MangaDetailsRecord(manga: manga, chapters: [], chapterStates: [:], updatedAt: .now)
        value.manga = manga
        value.updatedAt = .now
        try write(value)
        return value
    }

    @discardableResult
    func mergeChapters(_ chapters: [Chapter], for id: MangaIdentity) throws -> MangaDetailsRecord {
        let placeholder = Manga(
            id: id, title: "", url: nil, thumbnailURL: nil, description: nil,
            author: nil, artist: nil, status: nil, genres: [], language: nil
        )
        var value = record(for: id) ?? MangaDetailsRecord(manga: placeholder, chapters: [], chapterStates: [:], updatedAt: .now)
        value.chapters = chapters
        value.updatedAt = .now
        try write(value)
        return value
    }

    @discardableResult
    func updateState(
        for chapter: ChapterIdentity,
        _ update: @Sendable (inout ChapterReadingState) -> Void
    ) throws -> MangaDetailsRecord {
        guard var value = record(for: chapter.manga) else { throw APIError.invalidResponse }
        var state = value.chapterStates[chapter.chapterID] ?? ChapterReadingState()
        update(&state)
        value.chapterStates[chapter.chapterID] = state
        value.updatedAt = .now
        try write(value)
        return value
    }

    private func write(_ record: MangaDetailsRecord) throws {
        memory[record.manga.id] = record
        guard let directory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try encoder.encode(record).write(to: fileURL(for: record.manga.id, in: directory), options: .atomic)
    }

    private func fileURL(for id: MangaIdentity, in directory: URL) -> URL {
        let key = "\(id.sourceID)\u{0}\(id.mangaID)"
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: "\(digest).json")
    }
}
