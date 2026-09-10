import Foundation

nonisolated struct ChapterSequence: Sendable {
    let chapters: [Chapter]

    init(_ chapters: [Chapter]) {
        self.chapters = ChapterOrdering.newestFirst(chapters)
    }

    func chapter(after chapter: Chapter) -> Chapter? {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }), index > chapters.startIndex else { return nil }
        return chapters[index - 1]
    }

    func chapter(before chapter: Chapter) -> Chapter? {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }), index + 1 < chapters.endIndex else { return nil }
        return chapters[index + 1]
    }
}
