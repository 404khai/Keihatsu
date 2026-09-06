import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var collections: CollectionStore
    @EnvironmentObject private var readingHistory: ReadingHistoryModel
    @Namespace private var animation
    @State private var selectionMode: Bool = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var deletePrompt: DeletePrompt?
    @State private var searchText = ""

    private var filteredSections: [HistorySection] {
        collections.historySections(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var filteredReadingSections: [ReadingHistorySection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let calendar = Calendar.current
        let entries = readingHistory.entries.filter { entry in
            query.isEmpty
                || entry.manga.title.localizedCaseInsensitiveContains(query)
                || entry.chapter.name.localizedCaseInsensitiveContains(query)
                || entry.updatedAt.formatted(date: .abbreviated, time: .shortened).localizedCaseInsensitiveContains(query)
                || readingDateTitle(for: entry.updatedAt, calendar: calendar).localizedCaseInsensitiveContains(query)
        }

        return Dictionary(grouping: entries) { calendar.startOfDay(for: $0.updatedAt) }
            .map { day, entries in
                ReadingHistorySection(
                    date: day,
                    title: readingDateTitle(for: day, calendar: calendar),
                    entries: entries.sorted { $0.updatedAt > $1.updatedAt }
                )
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                ForEach(filteredReadingSections) { section in
                    VStack(alignment: .leading, spacing: 18) {
                        Text(section.title)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.8))

                        VStack(spacing: 18) {
                            ForEach(section.entries) { entry in
                                NavigationLink(value: MangaDetailsSeed(manga: entry.manga, fallbackChapters: [entry.chapter])) {
                                    ReadingHistoryRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Text("Sample history • Account sync coming soon").font(.caption).foregroundStyle(.secondary)
                if let error = collections.error { CatalogueMessage(message: error) { collections.reload() } }
                ForEach(filteredSections) { section in
                    VStack(alignment: .leading, spacing: 18) {
                        Text(section.date)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.8))

                        VStack(spacing: 18) {
                            ForEach(section.items) { item in
                                HistoryRow(
                                    item: item,
                                    showCheckboxes: selectionMode,
                                    isSelected: selectedItemIDs.contains(item.id),
                                    onToggleSelection: {
                                        toggleSelection(for: item.id)
                                    },
                                    onDelete: {
                                        deletePrompt = DeletePrompt.single(item: item)
                                    }
                                )
                                .onTapGesture {
                                    guard selectionMode else { return }
                                    toggleSelection(for: item.id)
                                }
                                .onLongPressGesture {
                                    selectionMode = true
                                    selectedItemIDs = [item.id]
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("History")
        .task { await readingHistory.refresh() }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            CarouselDetailView(seed: seed, animation: animation, origin: .history)
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search history"))
        .overlay {
            if filteredSections.isEmpty && filteredReadingSections.isEmpty {
                ContentUnavailableView(
                    "No History Found",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Try searching another title, chapter, date, or time.")
                )
            }
        }
        .toolbar {
            if selectionMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        selectionMode = false
                        selectedItemIDs.removeAll()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectionMode {
                        if !selectedItemIDs.isEmpty {
                            deletePrompt = DeletePrompt.multiple(ids: selectedItemIDs)
                        }
                    } else {
                        selectionMode = true
                    }
                } label: {
                    Image(systemName: "trash.fill")
                }
            }
        }
        .alert(item: $deletePrompt) { prompt in
            Alert(
                title: Text("Delete Entry"),
                message: Text(prompt.message),
                primaryButton: .destructive(Text("Delete")) {
                    performDelete(for: prompt)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private func performDelete(for prompt: DeletePrompt) {
        switch prompt.kind {
        case .single(let id):
            deleteItems(withIDs: [id])
        case .multiple(let ids):
            deleteItems(withIDs: ids)
        }
    }

    private func deleteItems(withIDs ids: Set<UUID>) {
        collections.deleteHistory(ids)

        selectedItemIDs.subtract(ids)

        if selectedItemIDs.isEmpty {
            selectionMode = false
        }
    }

    private func readingDateTitle(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

private struct ReadingHistorySection: Identifiable {
    let date: Date
    let title: String
    let entries: [ReaderProgressRecord]
    var id: Date { date }
}

private struct ReadingHistoryRow: View {
    let entry: ReaderProgressRecord

    var body: some View {
        HStack(spacing: 18) {
            CatalogueCover(url: entry.manga.thumbnailURL, referer: entry.manga.url)
                .frame(width: 78, height: 116)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text(entry.manga.title)
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(1)

                Text(entry.chapter.name)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text("Page \(entry.displayedPage) of \(max(entry.totalPages, 1)) • \(entry.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct HistoryRow: View {
    let item: HistoryItem
    let showCheckboxes: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            if showCheckboxes {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }

            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 78, height: 116)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(1)

                Text("\(item.chapter)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text("\(item.time)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if !showCheckboxes {
                HStack(spacing: 24) {
                    Button {
                    } label: { Image(systemName: "book.closed") }
                    .disabled(true)
                    .accessibilityLabel("Reading coming soon")

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.fill")
                    }
                }
                .font(.title2)
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        }
    }
}

private struct DeletePrompt: Identifiable {
    enum Kind {
        case single(UUID)
        case multiple(Set<UUID>)
    }

    let id = UUID()
    let kind: Kind
    let message: String

    static func single(item: HistoryItem) -> DeletePrompt {
        DeletePrompt(
            kind: .single(item.id),
            message: "Are you sure you want to delete \(item.title) from your history?"
        )
    }

    static func multiple(ids: Set<UUID>) -> DeletePrompt {
        DeletePrompt(
            kind: .multiple(ids),
            message: "Are you sure you want to delete \(ids.count) selected history entries?"
        )
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .appEnvironment(.preview())
    }
}
