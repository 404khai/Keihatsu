import Foundation

nonisolated struct ReadingStatistics {
    struct Day: Identifiable {
        let date: Date
        let minutes: Double
        var id: Date { date }
        var day: String { date.formatted(Date.FormatStyle(timeZone: .gmt).weekday(.abbreviated)) }
    }
    struct Month: Identifiable {
        let date: Date
        let hours: Double
        var id: Date { date }
        var month: String { date.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated)) }
    }
    struct Genre: Identifiable {
        let genre: String
        let chapters: Int
        let percent: Int
        var id: String { genre }
    }

    let daily: [Day]
    let monthly: [Month]
    let genres: [Genre]
    let chaptersRead: Int
    let titlesOpened: Int
    let activeDays: Int
    let streak: Int
    let previousWeekMinutes: Double
    var weekMinutes: Double { daily.reduce(0) { $0 + $1.minutes } }
    var dailyAverage: Double { weekMinutes / 7 }

    init(statistics: UserStatistics, history: [ReaderProgressRecord], now: Date = .now) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let today = calendar.startOfDay(for: now)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        // Duration is authoritative account data, never inferred from latest chapter timestamps.
        let minutes = Dictionary(uniqueKeysWithValues: (statistics.dailyReadingTimeMinutes ?? [:]).compactMap { key, value -> (Date, Double)? in
            guard let date = formatter.date(from: key), value.isFinite, value > 0, date <= today else { return nil }
            return (date, value)
        })
        daily = (-6...0).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            return Day(date: date, minutes: minutes[date] ?? 0)
        }
        previousWeekMinutes = (-13 ... -7).reduce(0) { result, offset in
            result + (minutes[calendar.date(byAdding: .day, value: offset, to: today)!] ?? 0)
        }
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        monthly = (-5...0).map { offset in
            let start = calendar.date(byAdding: .month, value: offset, to: monthStart)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return Month(date: start, hours: minutes.filter { $0.key >= start && $0.key < end }.values.reduce(0, +) / 60)
        }
        let completed = history.filter { $0.isRead }
        chaptersRead = completed.count
        titlesOpened = Set(history.map { $0.manga.id }).count
        var counts: [String: Int] = [:]
        for entry in completed {
            let names = Set(entry.manga.genres.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            for name in names.isEmpty ? ["Unknown"] : names { counts[name, default: 0] += 1 }
        }
        let total = counts.values.reduce(0, +)
        genres = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.map {
            Genre(genre: $0.key, chapters: $0.value, percent: Int((Double($0.value) / Double(max(total, 1)) * 100).rounded()))
        }
        let historyDays = Set(history.map { calendar.startOfDay(for: $0.updatedAt) }.filter { $0 <= today })
        let days = Set(minutes.keys).union(historyDays)
        activeDays = days.count
        var cursor = days.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        streak = count
    }

    static func duration(_ minutes: Double) -> String {
        let value = max(0, Int(minutes.rounded(.down)))
        return value >= 60 ? "\(value / 60) hr \(value % 60) min" : "\(value) min"
    }
}
