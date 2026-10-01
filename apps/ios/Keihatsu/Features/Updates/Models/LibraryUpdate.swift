import Foundation

nonisolated enum LibraryUpdateFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All chapters"
    case unread = "Unread"
    case downloaded = "Downloaded"

    var id: Self { self }
}

nonisolated struct LibraryUpdateItem: Identifiable, Sendable {
    let manga: Manga
    let chapter: Chapter
    let state: ChapterReadingState
    let coverAsset: String?

    var id: ChapterIdentity { chapter.id }
    var uploadedAt: Date? { chapter.uploadedAt }
}

nonisolated struct LibraryUpdateDay: Identifiable, Sendable {
    let date: Date
    let items: [LibraryUpdateItem]

    var id: Date { date }
}
