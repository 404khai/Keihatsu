import Foundation

nonisolated struct AuthResponseDTO: Decodable, Sendable {
    let accessToken: String
    let user: UserDTO
}

nonisolated struct UserDTO: Codable, Sendable {
    let id: String
    let email: String?
    let username: String?
    let bio: String?
    let createdAt: String?
    let isProfilePublic: Bool?
    let avatarHue: Double?
    let avatarShape: Double?
    let avatarExpression: String?
    let avatarAnimated: Bool?

    func domain(statistics: UserStatistics = .empty) -> UserAccount {
        UserAccount(
            id: id,
            email: email,
            username: username?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? email?.components(separatedBy: "@").first ?? "Reader",
            bio: bio,
            createdAt: createdAt.flatMap(APIDate.parse),
            isProfilePublic: isProfilePublic ?? true,
            avatar: AvatarConfiguration(
                hue: avatarHue,
                shape: avatarShape,
                expression: AvatarConfiguration.Expression(rawValue: avatarExpression ?? "happy") ?? .happy,
                animated: avatarAnimated ?? false
            ),
            statistics: statistics
        )
    }
}

nonisolated struct UserStatisticsDTO: Codable, Sendable {
    let libraryCount: Int?
    let totalReadingTimeMinutes: Int?
    let mangasReadToday: Int?
    let commentsCount: Int?
    let points: Int?

    var domain: UserStatistics {
        UserStatistics(
            libraryCount: libraryCount ?? 0,
            totalReadingTimeMinutes: totalReadingTimeMinutes ?? 0,
            mangasReadToday: mangasReadToday ?? 0,
            commentsCount: commentsCount ?? 0,
            points: points ?? 0
        )
    }
}

nonisolated struct UserPreferencesDTO: Codable, Sendable {
    let libraryDisplayStyle: String?
    let libraryItemsPerRow: Int?
    let overlayShowDownloaded: Bool?
    let overlayShowUnread: Bool?
    let overlayShowLanguage: Bool?
    let tabsShowCategories: Bool?
    let tabsShowItemCount: Bool?
    let categoriesDisplayMode: String?
    let sourcePreferences: [String: SourcePreferenceDTO]?

    enum CodingKeys: String, CodingKey {
        case libraryDisplayStyle = "library_display_style"
        case libraryItemsPerRow = "library_items_per_row"
        case overlayShowDownloaded = "overlay_show_downloaded"
        case overlayShowUnread = "overlay_show_unread"
        case overlayShowLanguage = "overlay_show_language"
        case tabsShowCategories = "tabs_show_categories"
        case tabsShowItemCount = "tabs_show_item_count"
        case categoriesDisplayMode = "categories_display_mode"
        case sourcePreferences = "source_preferences"
    }

    init(_ value: SyncedUserPreferences) {
        libraryDisplayStyle = value.libraryDisplayStyle
        libraryItemsPerRow = value.libraryItemsPerRow
        overlayShowDownloaded = value.overlayShowDownloaded
        overlayShowUnread = value.overlayShowUnread
        overlayShowLanguage = value.overlayShowLanguage
        tabsShowCategories = value.tabsShowCategories
        tabsShowItemCount = value.tabsShowItemCount
        categoriesDisplayMode = value.categoriesDisplayMode
        sourcePreferences = value.sourcePreferences.mapValues(SourcePreferenceDTO.init)
    }

    var domain: SyncedUserPreferences {
        let defaults = SyncedUserPreferences.default
        return SyncedUserPreferences(
            libraryDisplayStyle: libraryDisplayStyle ?? defaults.libraryDisplayStyle,
            libraryItemsPerRow: libraryItemsPerRow ?? defaults.libraryItemsPerRow,
            overlayShowDownloaded: overlayShowDownloaded ?? defaults.overlayShowDownloaded,
            overlayShowUnread: overlayShowUnread ?? defaults.overlayShowUnread,
            overlayShowLanguage: overlayShowLanguage ?? defaults.overlayShowLanguage,
            tabsShowCategories: tabsShowCategories ?? defaults.tabsShowCategories,
            tabsShowItemCount: tabsShowItemCount ?? defaults.tabsShowItemCount,
            categoriesDisplayMode: categoriesDisplayMode ?? defaults.categoriesDisplayMode,
            sourcePreferences: sourcePreferences?.mapValues(\.domain) ?? [:]
        )
    }
}

nonisolated struct SourcePreferenceDTO: Codable, Sendable {
    let enabled: Bool
    let pinned: Bool
    init(_ value: SyncedSourcePreference) { enabled = value.enabled; pinned = value.pinned }
    var domain: SyncedSourcePreference { .init(enabled: enabled, pinned: pinned) }
}

nonisolated struct PublicProfileDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let bio: String?
    let createdAt: String?
    let isProfilePublic: Bool?
    let avatarHue: Double?
    let avatarShape: Double?
    let avatarExpression: String?
    let avatarAnimated: Bool?
    let stats: UserStatisticsDTO?
    let library: [PublicLibraryEntryDTO]?

    var domain: PublicUserProfile {
        let user = UserDTO(
            id: id, email: nil, username: username, bio: bio, createdAt: createdAt,
            isProfilePublic: isProfilePublic, avatarHue: avatarHue, avatarShape: avatarShape,
            avatarExpression: avatarExpression, avatarAnimated: avatarAnimated
        ).domain(statistics: stats?.domain ?? .empty)
        return PublicUserProfile(account: user, library: (library ?? []).map(\.domain))
    }
}

nonisolated struct PublicLibraryEntryDTO: Decodable, Sendable {
    let id: String
    let mangaId: String
    let sourceId: String
    let title: String
    let thumbnailUrl: String?
    let author: String?
    let totalChapters: Int?
    let lastReadAt: String?
    let dateAddedAt: String?

    var domain: PublicLibraryItem {
        PublicLibraryItem(
            id: id,
            manga: Manga(
                id: .init(sourceID: sourceId, mangaID: mangaId), title: title, url: nil,
                thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)), description: nil,
                author: author, artist: nil, status: nil, genres: [], language: nil
            ),
            totalChapters: totalChapters ?? 0,
            lastReadAt: lastReadAt.flatMap(APIDate.parse),
            dateAddedAt: dateAddedAt.flatMap(APIDate.parse)
        )
    }
}

nonisolated enum APIDate {
    static func parse(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }
}

private extension String {
    nonisolated var nilIfEmpty: String? { isEmpty ? nil : self }
}
