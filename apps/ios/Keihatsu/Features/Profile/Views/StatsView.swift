import Charts
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    @EnvironmentObject private var session: AccountSessionStore
    @EnvironmentObject private var history: ReadingHistoryModel

    private var stats: ReadingStatistics {
        ReadingStatistics(statistics: session.account?.statistics ?? .empty, history: history.chapterEntries)
    }
    private var dailyReading: [ReadingStatistics.Day] { stats.daily }
    private var genres: [ReadingStatistics.Genre] { stats.genres }
    private var monthlyReading: [ReadingStatistics.Month] { stats.monthly }
    private var genreColors: [Color] { genres.indices.map { [accent, .blue, .purple, .orange, .pink, .teal][$0 % 6] } }

    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let error = session.error {
                    CatalogueMessage(message: error) { Task { await refresh() } }
                }
                if history.chapterEntries.isEmpty && stats.activeDays == 0 {
                    Text("Start reading to build your stats.").foregroundStyle(.secondary)
                }
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
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task(id: session.account?.id) { await refresh() }
        .refreshable { await refresh() }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading in the last 7 days")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(ReadingStatistics.duration(stats.weekMinutes))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Previous 7 days: \(ReadingStatistics.duration(stats.previousWeekMinutes))")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(accent)
                }

                Spacer()
            }

            Text("All time: \(ReadingStatistics.duration(Double(session.account?.statistics.totalReadingTimeMinutes ?? 0)))")
                .font(.footnote).foregroundStyle(.secondary)
            if session.account?.statistics.dailyReadingTimeMinutes == nil {
                Text("Daily reading time is unavailable. Sign in or pull to refresh account stats.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(stats.streak) day reading streak")
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
                value: String(stats.chaptersRead),
                label: "Chapters read"
            )
            StatMetricCard(
                icon: "rectangle.stack.fill",
                color: .blue,
                value: String(stats.titlesOpened),
                label: "Titles opened"
            )
            StatMetricCard(
                icon: "clock.fill",
                color: .purple,
                value: ReadingStatistics.duration(stats.dailyAverage),
                label: "Daily average"
            )
            StatMetricCard(
                icon: "calendar.badge.checkmark",
                color: .orange,
                value: String(stats.activeDays),
                label: "Active days"
            )
        }
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(title: "Daily reading", subtitle: "Last 7 days • Minutes (UTC)", icon: "chart.bar.fill", color: accent)

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
                AxisMarks(position: .leading, values: .automatic) {
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel()
                }
            }
            .chartXAxis { AxisMarks { AxisValueLabel() } }
            .frame(height: 190)
            .accessibilityLabel("Daily reading: \(ReadingStatistics.duration(stats.weekMinutes)) in the last 7 days")
        }
        .statsCard()
    }

    private var genreChartCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(title: "Reading mix", subtitle: "Completed chapters • Multiple genres may apply", icon: "chart.pie.fill", color: .pink)

            if genres.isEmpty {
                Text("Complete a chapter to see your reading mix.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
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
                        range: genreColors
                    )
                    .chartLegend(.hidden)

                    VStack(spacing: 2) {
                        Text(String(stats.chaptersRead))
                            .font(.title.bold())
                            .fontDesign(.rounded)
                        Text("chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 156, height: 156)
                .accessibilityLabel("Reading mix: \(stats.chaptersRead) completed chapters")

                VStack(alignment: .leading, spacing: 13) {
                    ForEach(Array(zip(genres, genreColors)), id: \.0.id) { item, color in
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
            chartHeader(title: "Six month trend", subtitle: "Reading hours (UTC)", icon: "waveform.path.ecg", color: .blue)

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
            .accessibilityLabel("Reading hours over the last six months")
        }
        .statsCard()
    }

    private func refresh() async {
        await history.refreshFromAccount()
        await session.refreshStatistics()
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

#Preview {
    let environment = AppEnvironment(services: .preview())
    NavigationStack {
        StatsView()
            .environmentObject(environment.preferencesStore)
            .environmentObject(environment.accountSession)
            .environmentObject(environment.readingHistory)
    }
}
