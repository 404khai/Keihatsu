import Foundation

nonisolated struct OnboardingPage: Decodable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let image: String
}
