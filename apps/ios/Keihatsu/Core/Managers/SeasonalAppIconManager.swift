import UIKit
import OSLog

@MainActor
final class SeasonalAppIconManager {
    static let shared = SeasonalAppIconManager()
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Keihatsu", category: "SeasonalAppIcon")
    private let supportsAlternateIcons: () -> Bool
    private let currentIconName: () -> String?
    private let applyIconName: (String?) async throws -> Void
    private var isSyncing = false

    init(application: UIApplication? = nil) {
        let application = application ?? .shared
        supportsAlternateIcons = { application.supportsAlternateIcons }
        currentIconName = { application.alternateIconName }
        applyIconName = { iconName in
            try await withCheckedThrowingContinuation { continuation in
                application.setAlternateIconName(iconName) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }

    init(
        supportsAlternateIcons: @escaping () -> Bool,
        currentIconName: @escaping () -> String?,
        applyIconName: @escaping (String?) async throws -> Void
    ) {
        self.supportsAlternateIcons = supportsAlternateIcons
        self.currentIconName = currentIconName
        self.applyIconName = applyIconName
    }

    func sync(for date: Date = .now, calendar: Calendar = .current) async {
        guard supportsAlternateIcons(), !isSyncing else { return }
        let desired = Self.alternateIconName(for: .current(for: date, calendar: calendar))
        guard currentIconName() != desired else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await applyIconName(desired)
        } catch {
            Self.logger.error("Unable to select seasonal icon: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func alternateIconName(for season: KeihatsuSeason) -> String? {
        switch season {
        case .spring: "KeihatsuSpringIcon"
        case .summer: nil
        case .autumn: "KeihatsuAutumnIcon"
        case .winter: "KeihatsuWinterIcon"
        }
    }
}
