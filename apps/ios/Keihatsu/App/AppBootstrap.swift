import Combine
import Foundation

@MainActor
final class AppBootstrap: ObservableObject {
    enum Stage: Equatable { case onboarding, accountEntry, mainApp }

    @Published private(set) var stage: Stage
    private let defaults: UserDefaults
    private let onboardingKey = "keihatsu.hasSeenOnboarding"
    private let guestEntryKey = "keihatsu.hasEnteredAsGuest"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.bool(forKey: guestEntryKey) {
            stage = .mainApp
        } else if defaults.bool(forKey: onboardingKey) {
            stage = .accountEntry
        } else {
            stage = .onboarding
        }
    }

    func completeOnboarding() {
        defaults.set(true, forKey: onboardingKey)
        stage = .accountEntry
    }

    func enterAsGuest() {
        defaults.set(true, forKey: onboardingKey)
        defaults.set(true, forKey: guestEntryKey)
        stage = .mainApp
    }

    func enterAuthenticated() {
        defaults.set(true, forKey: onboardingKey)
        defaults.removeObject(forKey: guestEntryKey)
        stage = .mainApp
    }

    func requireAccountEntry() {
        defaults.removeObject(forKey: guestEntryKey)
        stage = .accountEntry
    }
}
