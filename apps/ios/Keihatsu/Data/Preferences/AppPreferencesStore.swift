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
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if
            let data = userDefaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(LocalUserPreferences.self, from: data)
        {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }

    func reset() {
        preferences = .default
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
