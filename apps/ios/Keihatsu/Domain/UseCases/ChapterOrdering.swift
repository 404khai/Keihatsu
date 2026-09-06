import Foundation

nonisolated enum ChapterOrdering {
    /// Newest first for detail-screen scanning. Numeric chapters include fractional values;
    /// specials without a positive number fall back to date, name, then opaque ID.
    static func newestFirst(_ chapters: [Chapter]) -> [Chapter] {
        chapters.sorted { lhs, rhs in
            let lhsNumeric = lhs.number.isFinite && lhs.number > 0
            let rhsNumeric = rhs.number.isFinite && rhs.number > 0
            if lhsNumeric != rhsNumeric { return lhsNumeric }
            if lhsNumeric, lhs.number != rhs.number { return lhs.number > rhs.number }
            if lhs.uploadedAt != rhs.uploadedAt {
                return (lhs.uploadedAt ?? .distantPast) > (rhs.uploadedAt ?? .distantPast)
            }
            let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.id.chapterID < rhs.id.chapterID
        }
    }

    static func oldestFirst(_ chapters: [Chapter]) -> [Chapter] {
        chapters.sorted { lhs, rhs in
            let lhsNumeric = lhs.number.isFinite && lhs.number > 0
            let rhsNumeric = rhs.number.isFinite && rhs.number > 0
            if lhsNumeric != rhsNumeric { return lhsNumeric }
            if lhsNumeric, lhs.number != rhs.number { return lhs.number < rhs.number }
            if lhs.uploadedAt != rhs.uploadedAt {
                return (lhs.uploadedAt ?? .distantPast) < (rhs.uploadedAt ?? .distantPast)
            }
            let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.id.chapterID < rhs.id.chapterID
        }
    }
}
