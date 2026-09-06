import Foundation

nonisolated enum ResolveResumeChapter {
    static func callAsFunction(
        chapters: [Chapter],
        states: [String: ChapterReadingState]
    ) -> ResumeChapter? {
        let readingOrder = ChapterOrdering.oldestFirst(chapters)
        guard let oldest = readingOrder.first else { return nil }

        let history = readingOrder.compactMap { chapter -> (Chapter, ChapterReadingState)? in
            guard let state = states[chapter.id.chapterID], state.lastReadAt != nil else { return nil }
            return (chapter, state)
        }
        guard let recent = history.max(by: {
            ($0.1.lastReadAt ?? .distantPast) < ($1.1.lastReadAt ?? .distantPast)
        }) else {
            return ResumeChapter(chapter: oldest, pageIndex: nil, hasHistory: false)
        }

        if !recent.1.isRead {
            return ResumeChapter(chapter: recent.0, pageIndex: recent.1.pageIndex, hasHistory: true)
        }
        guard let index = readingOrder.firstIndex(where: { $0.id == recent.0.id }),
              readingOrder.indices.contains(index + 1) else {
            return ResumeChapter(chapter: recent.0, pageIndex: recent.1.pageIndex, hasHistory: true)
        }
        return ResumeChapter(chapter: readingOrder[index + 1], pageIndex: nil, hasHistory: true)
    }
}
