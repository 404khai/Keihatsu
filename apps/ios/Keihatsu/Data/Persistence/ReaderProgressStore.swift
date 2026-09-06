import CryptoKit
import Foundation

actor ReaderProgressStore {
    private let fileURL: URL?
    private var records: [ChapterIdentity: ReaderProgressRecord] = [:]
    private var hasLoaded = false
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
            fileURL = nil
            return
        }
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let digest = SHA256.hash(data: Data(namespace.utf8)).map { String(format: "%02x", $0) }.joined()
        fileURL = base?
            .appending(path: "Keihatsu/ReaderProgress/\(digest)", directoryHint: .isDirectory)
            .appending(path: "progress.json")
    }

    func progress(for chapter: ChapterIdentity) -> ReaderProgressRecord? {
        loadIfNeeded()
        return records[chapter]
    }

    func recent() -> [ReaderProgressRecord] {
        loadIfNeeded()
        var seenManga = Set<MangaIdentity>()
        return records.values
            .filter { $0.totalPages > 0 }
            .sorted { $0.updatedAt > $1.updatedAt }
            .filter { seenManga.insert($0.manga.id).inserted }
    }

    func save(_ progress: ReaderProgressRecord) throws {
        loadIfNeeded()
        records[progress.id] = progress
        try persist()
    }

    func setBookmark(_ isBookmarked: Bool, manga: Manga, chapter: Chapter) throws {
        loadIfNeeded()
        var progress = records[chapter.id] ?? ReaderProgressRecord(
            manga: manga,
            chapter: chapter,
            pageIndex: 0,
            intraPageAnchor: 0,
            totalPages: 0,
            activeReadingSeconds: 0,
            isRead: false,
            isBookmarked: false,
            updatedAt: .now
        )
        progress.isBookmarked = isBookmarked
        progress.updatedAt = .now
        records[chapter.id] = progress
        try persist()
    }

    func delete(for manga: MangaIdentity) throws {
        loadIfNeeded()
        records = records.filter { $0.key.manga != manga }
        try persist()
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let values = try? decoder.decode([ReaderProgressRecord].self, from: data) else { return }
        records = Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
    }

    private func persist() throws {
        guard let fileURL else { return }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(Array(records.values)).write(to: fileURL, options: .atomic)
    }
}
