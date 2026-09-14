import Foundation
import Testing
@testable import Keihatsu

@Suite
struct SeasonalBrandingTests {
    @Test(arguments: [
        (1, KeihatsuSeason.winter),
        (2, .winter),
        (3, .spring),
        (5, .spring),
        (6, .summer),
        (8, .summer),
        (9, .autumn),
        (11, .autumn),
        (12, .winter)
    ])
    func resolvesBrandingSeason(month: Int, expected: KeihatsuSeason) {
        #expect(KeihatsuSeason(month: month) == expected)
    }

    @Test func mapsSummerToPrimaryAndOtherSeasonsToExactAlternateNames() {
        #expect(SeasonalAppIconManager.alternateIconName(for: .spring) == "KeihatsuSpringIcon")
        #expect(SeasonalAppIconManager.alternateIconName(for: .summer) == nil)
        #expect(SeasonalAppIconManager.alternateIconName(for: .autumn) == "KeihatsuAutumnIcon")
        #expect(SeasonalAppIconManager.alternateIconName(for: .winter) == "KeihatsuWinterIcon")
    }

    @Test @MainActor func skipsAnIconChangeWhenTheDesiredIconIsAlreadySelected() async {
        var appliedNames: [String?] = []
        let manager = SeasonalAppIconManager(
            supportsAlternateIcons: { true },
            currentIconName: { "KeihatsuAutumnIcon" },
            applyIconName: { appliedNames.append($0) }
        )

        await manager.sync(for: date(month: 9), calendar: calendar)

        #expect(appliedNames.isEmpty)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(month: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: 1))!
    }
}
