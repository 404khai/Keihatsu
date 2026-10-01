import SwiftUI

struct LibraryUpdatesCalendarView: View {
    @Environment(\.keihatsuTheme) private var theme
    @ObservedObject var model: LibraryUpdatesViewModel
    let animation: Namespace.ID
    @State private var visibleMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var showingScheduleInfo = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = Calendar.current.veryShortStandaloneWeekdaySymbols

    private var selectedItems: [LibraryUpdateItem] {
        model.scheduledItems(on: selectedDate, calendar: calendar)
    }

    private var monthDays: [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: visibleMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)) else { return [] }
        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + dayRange.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: first)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                monthHeader
                weekdayHeader
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(monthDays.indices, id: \.self) { index in
                        if let date = monthDays[index] { dayCell(date) }
                        else { Color.clear.frame(height: 52) }
                    }
                }

                HStack(spacing: 8) {
                    Text(sectionLabel).font(.title3.weight(.semibold))
                    if !selectedItems.isEmpty {
                        Text("\(selectedItems.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(.systemBackground))
                            .frame(width: 23, height: 23)
                            .background(theme.colors.accent, in: Circle())
                    }
                }
                .padding(.top, 6)

                if selectedItems.isEmpty {
                    ContentUnavailableView(
                        "No releases scheduled",
                        systemImage: "calendar.badge.clock",
                        description: Text("Choose a date marked with an accent dot.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(selectedItems) { item in
                            NavigationLink(value: MangaDetailsSeed(manga: item.manga, coverAsset: item.coverAsset)) {
                                HStack(spacing: 14) {
                                    CatalogueCover(
                                        url: item.manga.thumbnailURL,
                                        referer: item.manga.url,
                                        asset: item.coverAsset
                                    )
                                    .frame(width: 54, height: 76)
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                    Text(item.manga.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.screenPadding)
            .padding(.vertical, theme.spacing.lg)
        }
        .navigationTitle("Upcoming")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("About release predictions", systemImage: "questionmark.circle") {
                    showingScheduleInfo = true
                }
                .labelStyle(.iconOnly)
            }
        }
        .alert("Release predictions", isPresented: $showingScheduleInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Upcoming dates are estimated from each title’s recent upload weekday. Source schedules may change.")
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            MangaDetailView(seed: seed, animation: animation, origin: .library)
        }
    }

    private var monthHeader: some View {
        HStack {
            Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title2.weight(.semibold))
            Spacer()
            Button("Previous month", systemImage: "chevron.left") { shiftMonth(-1) }
                .labelStyle(.iconOnly)
            Button("Next month", systemImage: "chevron.right") { shiftMonth(1) }
                .labelStyle(.iconOnly)
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(orderedWeekdayLabels.indices, id: \.self) { index in
                Text(orderedWeekdayLabels[index])
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var orderedWeekdayLabels: [String] {
        let offset = max(calendar.firstWeekday - 1, 0)
        return Array(weekdayLabels[offset...]) + Array(weekdayLabels[..<offset])
    }

    private func dayCell(_ date: Date) -> some View {
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let count = min(model.scheduledItems(on: date, calendar: calendar).count, 3)
        let isPast = date < calendar.startOfDay(for: .now)
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.body.weight(selected ? .bold : .medium))
                    .frame(width: 34, height: 34)
                    .overlay {
                        if selected { Circle().stroke(.primary, lineWidth: 1.5) }
                    }
                HStack(spacing: 2) {
                    ForEach(0..<count, id: \.self) { _ in
                        Circle().fill(theme.colors.accent).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .opacity(isPast ? 0.38 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(count == 0 ? "No predicted releases" : "\(count) or more predicted releases")
    }

    private var sectionLabel: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if calendar.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        return selectedDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    private func shiftMonth(_ value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        visibleMonth = month
        selectedDate = month
    }
}
