import Foundation
import XCTest
@testable import Keihatsu

final class DownloadTests: XCTestCase {
    func testPackagesVerifiedPagesAsCBZAtFlutterCompatiblePath() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "keihatsu-download-test-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ChapterArchiveStore(
            documentsRoot: root.appending(path: "Documents", directoryHint: .isDirectory),
            applicationSupportRoot: root.appending(path: "Support", directoryHint: .isDirectory)
        )
        let id = UUID()
        let staging = try await store.stagingDirectory(for: id)
        let first = staging.appending(path: "first.png")
        let second = staging.appending(path: "second.png")
        let firstBytes = try XCTUnwrap(Data(base64Encoded: Self.onePixelPNG))
        let secondBytes = firstBytes + Data([0])
        try firstBytes.write(to: first)
        try secondBytes.write(to: second)

        let identity = DownloadIdentity(sourceID: "manhuatop", mangaID: "solo-leveling", chapterID: "chapter/42?lang=en")
        let request = ChapterDownloadRequest(
            identity: identity, ownerID: "guest", extensionName: "ManhuaTop",
            mangaTitle: "Solo Leveling", chapterName: "Chapter 42", chapterNumber: 42, thumbnailURL: nil
        )
        let record = ChapterDownloadRecord(
            id: id, request: request, status: .packaging,
            pages: [
                DownloadPageRecord(index: 0, remoteURL: URL(string: "https://example.com/1.png")!, refererURL: nil, stagedFilename: first.lastPathComponent, byteCount: Int64(firstBytes.count)),
                DownloadPageRecord(index: 1, remoteURL: URL(string: "https://example.com/2.png")!, refererURL: nil, stagedFilename: second.lastPathComponent, byteCount: Int64(secondBytes.count))
            ],
            activePageIndex: nil, activeTaskIdentifier: nil, priority: 0, progress: 1,
            errorMessage: nil, archiveByteCount: 0, createdAt: .now, updatedAt: .now
        )

        let archive = try await store.package(record: record)

        XCTAssertEqual(archive.pathExtension, "cbz")
        XCTAssertTrue(archive.path.hasSuffix("Keihatsu/downloads/manhuatop/solo-leveling/42.cbz"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: archive.deletingPathExtension().path), "Downloaded chapters must not remain as image directories")
        let archiveExists = await store.contains(identity)
        XCTAssertTrue(archiveExists)

        let chapter = ChapterIdentity(manga: MangaIdentity(sourceID: identity.sourceID, mangaID: identity.mangaID), chapterID: identity.chapterID)
        let pages = try await store.readerPages(for: chapter)
        XCTAssertEqual(pages.count, 2)
        let restoredFirst = try await store.data(for: pages[0].imageURL)
        let restoredSecond = try await store.data(for: pages[1].imageURL)
        let storage = await store.storageSnapshot()
        XCTAssertEqual(restoredFirst, firstBytes)
        XCTAssertEqual(restoredSecond, secondBytes)
        XCTAssertEqual(storage.archiveCount, 1)
    }

    func testDownloadQueuePersistsStatusAndPriority() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "keihatsu-queue-test-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = DownloadRecordStore(namespace: "tests", root: root)
        let identity = DownloadIdentity(sourceID: "source", mangaID: "manga", chapterID: "chapter")
        let request = ChapterDownloadRequest(
            identity: identity, ownerID: "reader", extensionName: "Source", mangaTitle: "Manga",
            chapterName: "Chapter 1", chapterNumber: 1, thumbnailURL: nil
        )
        let record = ChapterDownloadRecord(
            id: UUID(), request: request, status: .paused, pages: [], activePageIndex: nil,
            activeTaskIdentifier: nil, priority: 7, progress: 0.4, errorMessage: nil,
            archiveByteCount: 0, createdAt: .now, updatedAt: .now
        )

        try await store.save([record])
        let restored = await DownloadRecordStore(namespace: "tests", root: root).load()

        XCTAssertEqual(restored.first?.status, .paused)
        XCTAssertEqual(restored.first?.priority, 7)
        XCTAssertEqual(restored.first?.request.ownerID, "reader")
    }

    private static let onePixelPNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZQmcAAAAASUVORK5CYII="
}
