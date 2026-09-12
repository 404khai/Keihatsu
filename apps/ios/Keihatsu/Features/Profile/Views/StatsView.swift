import Charts
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private let dailyReading = ReadingDay.preview
    private let genres = GenreSlice.preview
    private let monthlyReading = ReadingMonth.preview

    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                overviewCard
                metricGrid
                weeklyChartCard
                genreChartCard
                monthlyChartCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading this week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("12 hr 24 min")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("2 hr 18 min more than last week")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(accent)
                }

                Spacer()

                Text("PREVIEW DATA")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }

            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("7 day reading streak")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.up.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.24), Color(.secondarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatMetricCard(
                icon: "books.vertical.fill",
                color: accent,
                value: "38",
                label: "Chapters read"
            )
            StatMetricCard(
                icon: "rectangle.stack.fill",
                color: .blue,
                value: "11",
                label: "Titles opened"
            )
            StatMetricCard(
                icon: "clock.fill",
                color: .purple,
                value: "20 min",
                label: "Daily average"
            )
            StatMetricCard(
                icon: "calendar.badge.checkmark",
                color: .orange,
                value: "24",
                label: "Active days"
            )
        }
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(title: "Daily reading", subtitle: "Minutes read this week", icon: "chart.bar.fill", color: accent)

            Chart(dailyReading) { day in
                BarMark(
                    x: .value("Day", day.day),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(7)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 30, 60, 90]) {
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel()
                }
            }
            .chartXAxis { AxisMarks { AxisValueLabel() } }
            .frame(height: 190)
            .accessibilityLabel("Daily reading preview: 744 minutes total this week")
        }
        .statsCard()
    }

    private var genreChartCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(title: "Reading mix", subtitle: "Chapters by genre", icon: "chart.pie.fill", color: .pink)

            HStack(spacing: 22) {
                ZStack {
                    Chart(genres) { slice in
                        SectorMark(
                            angle: .value("Chapters", slice.chapters),
                            innerRadius: .ratio(0.66),
                            angularInset: 2
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Genre", slice.genre))
                    }
                    .chartForegroundStyleScale(
                        domain: genres.map(\.genre),
                        range: [accent, .blue, .purple, .orange]
                    )
                    .chartLegend(.hidden)

                    VStack(spacing: 2) {
                        Text("38")
                            .font(.title.bold())
                            .fontDesign(.rounded)
                        Text("chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 156, height: 156)
                .accessibilityLabel("Reading mix preview: Action 42 percent, Fantasy 29 percent, Romance 18 percent, Mystery 11 percent")

                VStack(alignment: .leading, spacing: 13) {
                    ForEach(Array(zip(genres, [accent, .blue, .purple, .orange])), id: \.0.id) { item, color in
                        HStack(spacing: 8) {
                            Circle().fill(color).frame(width: 9, height: 9)
                            Text(item.genre).font(.subheadline)
                            Spacer(minLength: 4)
                            Text("\(item.percent)%")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .statsCard()
    }

    private var monthlyChartCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(title: "Six month trend", subtitle: "Reading hours", icon: "waveform.path.ecg", color: .blue)

            Chart(monthlyReading) { month in
                AreaMark(
                    x: .value("Month", month.month),
                    y: .value("Hours", month.hours)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent.opacity(0.38), accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Month", month.month),
                    y: .value("Hours", month.hours)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(accent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Month", month.month),
                    y: .value("Hours", month.hours)
                )
                .foregroundStyle(accent)
                .symbolSize(34)
            }
            .chartYAxis(.hidden)
            .chartXAxis { AxisMarks { AxisValueLabel() } }
            .frame(height: 170)
            .accessibilityLabel("Six month reading trend preview, increasing from 19 to 48 hours")
        }
        .statsCard()
    }

    private func chartHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct StatMetricCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private extension View {
    func statsCard() -> some View {
        padding(20)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

private struct ReadingDay: Identifiable {
    let day: String
    let minutes: Int
    var id: String { day }

    static let preview = [
        ReadingDay(day: "Mon", minutes: 72),
        ReadingDay(day: "Tue", minutes: 48),
        ReadingDay(day: "Wed", minutes: 95),
        ReadingDay(day: "Thu", minutes: 64),
        ReadingDay(day: "Fri", minutes: 126),
        ReadingDay(day: "Sat", minutes: 181),
        ReadingDay(day: "Sun", minutes: 158)
    ]
}

private struct GenreSlice: Identifiable {
    let genre: String
    let chapters: Int
    let percent: Int
    var id: String { genre }

    static let preview = [
        GenreSlice(genre: "Action", chapters: 16, percent: 42),
        GenreSlice(genre: "Fantasy", chapters: 11, percent: 29),
        GenreSlice(genre: "Romance", chapters: 7, percent: 18),
        GenreSlice(genre: "Mystery", chapters: 4, percent: 11)
    ]
}

private struct ReadingMonth: Identifiable {
    let month: String
    let hours: Double
    var id: String { month }

    static let preview = [
        ReadingMonth(month: "Apr", hours: 19),
        ReadingMonth(month: "May", hours: 25),
        ReadingMonth(month: "Jun", hours: 22),
        ReadingMonth(month: "Jul", hours: 34),
        ReadingMonth(month: "Aug", hours: 39),
        ReadingMonth(month: "Sep", hours: 48)
    ]
}

#Preview {
    NavigationStack {
        StatsView()
            .environmentObject(AppPreferencesStore(userDefaults: .standard))
    }
}
