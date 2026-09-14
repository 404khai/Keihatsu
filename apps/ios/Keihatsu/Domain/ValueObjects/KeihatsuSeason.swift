import Foundation

nonisolated enum KeihatsuSeason: String, CaseIterable, Sendable {
    case spring
    case summer
    case autumn
    case winter

    init(month: Int) {
        switch month {
        case 3...5: self = .spring
        case 6...8: self = .summer
        case 9...11: self = .autumn
        default: self = .winter
        }
    }

    static func current(for date: Date, calendar: Calendar = .current) -> Self {
        Self(month: calendar.component(.month, from: date))
    }
}
