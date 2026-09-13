import Combine
import Foundation

@MainActor
final class AppPreferencesStore: ObservableObject {
    @Published var preferences: LocalUserPreferences {
        didSet {
            save()
        }
    }

    private let storageKey = "keihatsu.localUserPreferences"
    private let liveActivityDetailsMigrationKey = "keihatsu.migrations.liveActivityDetailsDefault.v1"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        var initialPreferences: LocalUserPreferences
        if
            let data = userDefaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(LocalUserPreferences.self, from: data)
        {
            initialPreferences = decoded
        } else {
            initialPreferences = .default
        }

        let shouldMigrateLiveActivityDetails = !userDefaults.bool(forKey: liveActivityDetailsMigrationKey)
        if shouldMigrateLiveActivityDetails {
            initialPreferences.showLiveActivityMangaDetails = true
            userDefaults.set(true, forKey: liveActivityDetailsMigrationKey)
        }
        self.preferences = initialPreferences
        if shouldMigrateLiveActivityDetails { save() }
    }

    func reset() {
        preferences = .default
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
