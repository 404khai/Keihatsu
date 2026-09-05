import Foundation

struct LocalUserPreferences: Codable, Equatable {
    var accentHex: String
    var theme: KeihatsuThemePreference
    var appIcon: AppIconPreference
    var colorScheme: AppColorSchemePreference
    var readerDirection: ReaderDirectionPreference
    var readerBackground: ReaderBackgroundPreference
    var keepScreenAwake: Bool
    var incognitoModeEnabled: Bool
    var autoSyncEnabled: Bool
    var downloadOnWiFiOnly: Bool
    var saveChaptersForOffline: Bool
    var showChapterBadges: Bool
    var globalLibraryUpdatesEnabled: Bool
    var sourceWarningsEnabled: Bool
    var trackingSyncEnabled: Bool
    var diagnosticsEnabled: Bool

    init(
        accentHex: String,
        theme: KeihatsuThemePreference,
        appIcon: AppIconPreference,
        colorScheme: AppColorSchemePreference,
        readerDirection: ReaderDirectionPreference,
        readerBackground: ReaderBackgroundPreference,
        keepScreenAwake: Bool,
        incognitoModeEnabled: Bool,
        autoSyncEnabled: Bool,
        downloadOnWiFiOnly: Bool,
        saveChaptersForOffline: Bool,
        showChapterBadges: Bool,
        globalLibraryUpdatesEnabled: Bool,
        sourceWarningsEnabled: Bool,
        trackingSyncEnabled: Bool,
        diagnosticsEnabled: Bool
    ) {
        self.accentHex = accentHex
        self.theme = theme
        self.appIcon = appIcon
        self.colorScheme = colorScheme
        self.readerDirection = readerDirection
        self.readerBackground = readerBackground
        self.keepScreenAwake = keepScreenAwake
        self.incognitoModeEnabled = incognitoModeEnabled
        self.autoSyncEnabled = autoSyncEnabled
        self.downloadOnWiFiOnly = downloadOnWiFiOnly
        self.saveChaptersForOffline = saveChaptersForOffline
        self.showChapterBadges = showChapterBadges
        self.globalLibraryUpdatesEnabled = globalLibraryUpdatesEnabled
        self.sourceWarningsEnabled = sourceWarningsEnabled
        self.trackingSyncEnabled = trackingSyncEnabled
        self.diagnosticsEnabled = diagnosticsEnabled
    }

    init(from decoder: Decoder) throws {
        let defaults = LocalUserPreferences.default
        let container = try decoder.container(keyedBy: CodingKeys.self)

        accentHex = try container.decodeIfPresent(String.self, forKey: .accentHex) ?? defaults.accentHex
        theme = try container.decodeIfPresent(KeihatsuThemePreference.self, forKey: .theme) ?? defaults.theme
        appIcon = try container.decodeIfPresent(AppIconPreference.self, forKey: .appIcon) ?? defaults.appIcon
        colorScheme = try container.decodeIfPresent(AppColorSchemePreference.self, forKey: .colorScheme) ?? defaults.colorScheme
        readerDirection = try container.decodeIfPresent(ReaderDirectionPreference.self, forKey: .readerDirection) ?? defaults.readerDirection
        readerBackground = try container.decodeIfPresent(ReaderBackgroundPreference.self, forKey: .readerBackground) ?? defaults.readerBackground
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? defaults.keepScreenAwake
        incognitoModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .incognitoModeEnabled) ?? defaults.incognitoModeEnabled
        autoSyncEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoSyncEnabled) ?? defaults.autoSyncEnabled
        downloadOnWiFiOnly = try container.decodeIfPresent(Bool.self, forKey: .downloadOnWiFiOnly) ?? defaults.downloadOnWiFiOnly
        saveChaptersForOffline = try container.decodeIfPresent(Bool.self, forKey: .saveChaptersForOffline) ?? defaults.saveChaptersForOffline
        showChapterBadges = try container.decodeIfPresent(Bool.self, forKey: .showChapterBadges) ?? defaults.showChapterBadges
        globalLibraryUpdatesEnabled = try container.decodeIfPresent(Bool.self, forKey: .globalLibraryUpdatesEnabled) ?? defaults.globalLibraryUpdatesEnabled
        sourceWarningsEnabled = try container.decodeIfPresent(Bool.self, forKey: .sourceWarningsEnabled) ?? defaults.sourceWarningsEnabled
        trackingSyncEnabled = try container.decodeIfPresent(Bool.self, forKey: .trackingSyncEnabled) ?? defaults.trackingSyncEnabled
        diagnosticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .diagnosticsEnabled) ?? defaults.diagnosticsEnabled
    }

    static let `default` = LocalUserPreferences(
        accentHex: "92BB57",
        theme: .verdant,
        appIcon: .default,
        colorScheme: .system,
        readerDirection: .vertical,
        readerBackground: .system,
        keepScreenAwake: true,
        incognitoModeEnabled: false,
        autoSyncEnabled: true,
        downloadOnWiFiOnly: true,
        saveChaptersForOffline: false,
        showChapterBadges: true,
        globalLibraryUpdatesEnabled: true,
        sourceWarningsEnabled: true,
        trackingSyncEnabled: false,
        diagnosticsEnabled: false
    )
}

enum KeihatsuThemePreference: String, Codable, CaseIterable, Identifiable {
    case verdant
    case moonlit
    case sakuraPulse
    case emberScript
    case oceanFrame
    case cinnabar
    case sandybrown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .verdant: return "Verdant"
        case .moonlit: return "Moonlit"
        case .sakuraPulse: return "Sakura Pulse"
        case .emberScript: return "Ember Script"
        case .oceanFrame: return "Ocean Frame"
        case .cinnabar: return "Cinnabar"
        case .sandybrown: return "Sandy Brown"
        }
    }

    var subtitle: String {
        switch self {
        case .verdant: return "Keihatsu green for actions and active icons"
        case .moonlit: return "Soft violet for night reading"
        case .sakuraPulse: return "Warm pink with a lively highlight"
        case .emberScript: return "Orange-red for dramatic panels"
        case .oceanFrame: return "Cool cyan for a calmer library"
        case .cinnabar: return "Bold red for a bold theme"
        case .sandybrown: return "Warm brown for a warm theme"
        }
    }

    var hex: String {
        switch self {
        case .verdant: return "8DE328"
        case .moonlit: return "A98BFF"
        case .sakuraPulse: return "FF6EA8"
        case .emberScript: return "FF7A3D"
        case .oceanFrame: return "42D9F5"
        case .cinnabar: return "E74236"
        case .sandybrown: return "FEB172"
        }
    }
}

enum AppIconPreference: String, Codable, CaseIterable, Identifiable {
    case `default`
    case dark
    case light

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default: return "Default"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
}

enum AppColorSchemePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum ReaderDirectionPreference: String, Codable, CaseIterable, Identifiable {
    case vertical
    case leftToRight
    case rightToLeft

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vertical: return "Vertical"
        case .leftToRight: return "Left to Right"
        case .rightToLeft: return "Right to Left"
        }
    }
}

enum ReaderBackgroundPreference: String, Codable, CaseIterable, Identifiable {
    case system
    case black
    case paper

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .black: return "Black"
        case .paper: return "Paper"
        }
    }
}
