import Foundation

nonisolated struct AvatarConfiguration: Codable, Equatable, Sendable {
    enum Expression: String, Codable, CaseIterable, Identifiable, Sendable {
        case idle, happy, sad, mad, surprised, wink, sleepy, smug, unsure, scared, love, shy, sick, thinking
        var id: Self { self }
        var label: String { rawValue.capitalized }
    }

    var hue: Double?
    var shape: Double?
    var expression: Expression
    var animated: Bool

    static let `default` = Self(hue: nil, shape: nil, expression: .happy, animated: false)
}

nonisolated struct UserStatistics: Codable, Equatable, Sendable {
    var libraryCount: Int
    var totalReadingTimeMinutes: Int
    var mangasReadToday: Int
    var commentsCount: Int
    var points: Int

    static let empty = Self(libraryCount: 0, totalReadingTimeMinutes: 0, mangasReadToday: 0, commentsCount: 0, points: 0)
}

nonisolated struct UserAccount: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var email: String?
    var username: String
    var bio: String?
    var createdAt: Date?
    var isProfilePublic: Bool
    var avatar: AvatarConfiguration
    var statistics: UserStatistics
}

nonisolated struct PublicLibraryItem: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let manga: Manga
    let totalChapters: Int
    let lastReadAt: Date?
    let dateAddedAt: Date?
}

nonisolated struct PublicUserProfile: Identifiable, Codable, Equatable, Sendable {
    let account: UserAccount
    var library: [PublicLibraryItem]
    var id: String { account.id }
}

nonisolated struct SyncedSourcePreference: Codable, Equatable, Sendable {
    var enabled: Bool
    var pinned: Bool
}

nonisolated struct SyncedUserPreferences: Codable, Equatable, Sendable {
    var libraryDisplayStyle: String
    var libraryItemsPerRow: Int
    var overlayShowDownloaded: Bool
    var overlayShowUnread: Bool
    var overlayShowLanguage: Bool
    var tabsShowCategories: Bool
    var tabsShowItemCount: Bool
    var categoriesDisplayMode: String
    var sourcePreferences: [String: SyncedSourcePreference]

    static let `default` = Self(
        libraryDisplayStyle: "grid",
        libraryItemsPerRow: 3,
        overlayShowDownloaded: true,
        overlayShowUnread: true,
        overlayShowLanguage: true,
        tabsShowCategories: true,
        tabsShowItemCount: true,
        categoriesDisplayMode: "comfortable grid",
        sourcePreferences: [:]
    )
}

nonisolated struct ProfileUpdate: Equatable, Sendable {
    var username: String
    var bio: String
    var avatar: AvatarConfiguration
}
