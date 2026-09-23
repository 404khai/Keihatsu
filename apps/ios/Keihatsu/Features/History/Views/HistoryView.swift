import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var collections: CollectionStore
    @EnvironmentObject private var readingHistory: ReadingHistoryModel
    @Namespace private var animation
    @State private var selectionMode: Bool = false
    @State private var selectedEntryIDs: Set<HistoryEntryID> = []
    @State private var deletePrompt: DeletePrompt?
    @State private var searchText = ""
    @State private var selectedDetails: MangaDetailsSeed?
    @State private var selectedReaderEntryID: ChapterIdentity?
    @State private var pendingLibraryManga: Manga?
    @State private var selectedCategories = Set<UUID>()

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
                                readingHistoryRow(entry)
                            }
                        }
                    }
                }
                if !collections.isAccountScoped {
                    Text("Sample history • Sign in to sync across devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let error = collections.error { CatalogueMessage(message: error) { collections.reload() } }
                ForEach(filteredSections) { section in
                    VStack(alignment: .leading, spacing: 18) {
                        Text(section.date)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.8))

                        VStack(spacing: 18) {
                            ForEach(section.items) { item in
                                let id = HistoryEntryID.sample(item.id)
                                HistoryRow(
                                    item: item,
                                    showCheckboxes: selectionMode,
                                    isSelected: selectedEntryIDs.contains(id),
                                    isInLibrary: isInLibrary(item),
                                    onToggleSelection: {
                                        toggleSelection(for: id)
                                    },
                                    onDelete: {
                                        deletePrompt = .single(id: id, title: item.title)
                                    }
                                )
                                .onTapGesture {
                                    guard selectionMode else { return }
                                    toggleSelection(for: id)
                                }
                                .onLongPressGesture {
                                    beginSelection(with: id)
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
        .scrollEdgeEffectStyle(.soft, for: .top)
        .task { await readingHistory.refresh() }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            MangaDetailView(seed: seed, animation: animation, origin: .history)
        }
        .navigationDestination(item: $selectedDetails) { seed in
            MangaDetailView(seed: seed, animation: animation, origin: .history)
        }
        .navigationDestination(item: $selectedReaderEntryID) { entryID in
            if let entry = readingHistory.entries.first(where: { $0.id == entryID }) {
                ReaderEntryView(
                    manga: entry.manga,
                    chapters: [entry.chapter],
                    context: ReaderLaunchContext(
                        chapter: entry.chapter.id,
                        origin: .history,
                        pageIndex: entry.pageIndex
                    )
                )
            }
        }
        .sheet(item: $pendingLibraryManga) { manga in
            categorySheet(for: manga)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
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
                        selectedEntryIDs.removeAll()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectionMode {
                        if !selectedEntryIDs.isEmpty {
                            deletePrompt = .multiple(ids: selectedEntryIDs)
                        }
                    } else {
                        selectionMode = true
                    }
                } label: {
                    Image(systemName: "trash.fill")
                }
                .disabled(selectionMode && selectedEntryIDs.isEmpty)
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

    @ViewBuilder
    private func readingHistoryRow(_ entry: ReaderProgressRecord) -> some View {
        let id = HistoryEntryID.reading(entry.manga.id)
        if selectionMode {
            ReadingHistoryRow(
                entry: entry,
                showCheckbox: true,
                isSelected: selectedEntryIDs.contains(id),
                isInLibrary: isInLibrary(entry),
                onCoverTap: { toggleSelection(for: id) },
                onChapterTap: { toggleSelection(for: id) },
                onLibraryTap: nil
            )
        } else {
            HStack(spacing: 0) {
                ReadingHistoryRow(
                    entry: entry,
                    showCheckbox: false,
                    isSelected: false,
                    isInLibrary: isInLibrary(entry),
                    onCoverTap: {
                        selectedDetails = MangaDetailsSeed(
                            manga: entry.manga,
                            fallbackChapters: [entry.chapter]
                        )
                    },
                    onChapterTap: { selectedReaderEntryID = entry.id },
                    onLibraryTap: isInLibrary(entry) ? nil : {
                        selectedCategories.removeAll()
                        pendingLibraryManga = entry.manga
                    }
                )

                Button(role: .destructive) {
                    deletePrompt = .single(id: id, title: entry.manga.title)
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(entry.manga.title) from history")
                .padding(.trailing, 14)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                LongPressGesture().onEnded { _ in
                    beginSelection(with: id)
                }
            )
        }
    }

    private func beginSelection(with id: HistoryEntryID) {
        selectionMode = true
        selectedEntryIDs = [id]
    }

    private func categorySheet(for manga: Manga) -> some View {
        NavigationStack {
            List {
                categoryRow("Default", isSelected: selectedCategories.isEmpty) {
                    selectedCategories.removeAll()
                }
                ForEach(collections.snapshot.categories) { category in
                    categoryRow(
                        category.name,
                        isSelected: selectedCategories.contains(category.id)
                    ) {
                        if selectedCategories.contains(category.id) {
                            selectedCategories.remove(category.id)
                        } else {
                            selectedCategories.insert(category.id)
                        }
                    }
                }
            }
            .navigationTitle("Select Categories")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button("Add to Library") {
                    _ = collections.addToLibrary(manga, categoryIDs: selectedCategories)
                    pendingLibraryManga = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
        }
    }

    private func categoryRow(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(title).foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func isInLibrary(_ entry: ReaderProgressRecord) -> Bool {
        collections.snapshot.library.contains { $0.item.manga?.id == entry.manga.id }
    }

    private func isInLibrary(_ item: HistoryItem) -> Bool {
        collections.snapshot.library.contains {
            $0.item.title.localizedCaseInsensitiveCompare(item.title) == .orderedSame
        }
    }

    private func toggleSelection(for id: HistoryEntryID) {
        if selectedEntryIDs.contains(id) {
            selectedEntryIDs.remove(id)
        } else {
            selectedEntryIDs.insert(id)
        }
    }

    private func performDelete(for prompt: DeletePrompt) {
        Task { await deleteItems(withIDs: prompt.ids) }
    }

    private func deleteItems(withIDs ids: Set<HistoryEntryID>) async {
        let readingIDs = Set(ids.compactMap { id -> MangaIdentity? in
            guard case .reading(let manga) = id else { return nil }
            return manga
        })
        let sampleIDs = Set(ids.compactMap { id -> UUID? in
            guard case .sample(let item) = id else { return nil }
            return item
        })

        if !sampleIDs.isEmpty { collections.deleteHistory(sampleIDs) }
        if !readingIDs.isEmpty { await readingHistory.delete(readingIDs) }

        selectedEntryIDs.subtract(ids)

        if selectedEntryIDs.isEmpty {
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
    let showCheckbox: Bool
    let isSelected: Bool
    let isInLibrary: Bool
    let onCoverTap: () -> Void
    let onChapterTap: () -> Void
    let onLibraryTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 18) {
            if showCheckbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }

            Button(action: onCoverTap) {
                CatalogueCover(url: entry.manga.thumbnailURL, referer: entry.manga.url)
                    .frame(width: 78, height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open details for \(entry.manga.title)")

            Button(action: onChapterTap) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.manga.title)
                        .font(.system(size: 18, weight: .medium))
                        .lineLimit(1)

                    Text(entry.chapter.displayName)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)

                    Text((entry.updatedAt.formatted(date: .omitted, time: .shortened)))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Continue \(entry.chapter.displayName)")

            if !showCheckbox {
                Button {
                    onLibraryTap?()
                } label: {
                    Image(systemName: isInLibrary ? "book.closed.fill" : "book.closed")
                        .font(.title2)
                        .foregroundStyle(isInLibrary ? Color.accentColor : .primary)
                }
                .buttonStyle(.plain)
                .disabled(onLibraryTap == nil)
                .accessibilityLabel(isInLibrary ? "In library" : "Add to library")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

private struct HistoryRow: View {
    let item: HistoryItem
    let showCheckboxes: Bool
    let isSelected: Bool
    let isInLibrary: Bool
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
                    Image(systemName: isInLibrary ? "book.closed.fill" : "book.closed")
                        .foregroundStyle(isInLibrary ? Color.accentColor : .primary)
                        .accessibilityLabel(isInLibrary ? "In library" : "Not in library")

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

private enum HistoryEntryID: Hashable {
    case reading(MangaIdentity)
    case sample(UUID)
}

private struct DeletePrompt: Identifiable {
    let id = UUID()
    let ids: Set<HistoryEntryID>
    let message: String

    static func single(id: HistoryEntryID, title: String) -> DeletePrompt {
        DeletePrompt(
            ids: [id],
            message: "Are you sure you want to delete \(title) from your history?"
        )
    }

    static func multiple(ids: Set<HistoryEntryID>) -> DeletePrompt {
        DeletePrompt(
            ids: ids,
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
