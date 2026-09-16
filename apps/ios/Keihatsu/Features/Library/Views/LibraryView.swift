import SwiftUI

struct LibraryView: View {
    let animation: Namespace.ID
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var collections: CollectionStore
    @EnvironmentObject private var readingHistory: ReadingHistoryModel
    @EnvironmentObject private var options: LibraryOptionsStore
    @EnvironmentObject private var downloads: DownloadCoordinator
    @State private var selectedCategory: UUID?
    @State private var searchText = ""
    @State private var showingControls = false
    @State private var showingCategories = false

    private var currentEntries: [LibraryEntry] {
        options.options.filtered(
            collections.snapshot.library,
            category: selectedCategory,
            query: searchText,
            downloadedCount: downloadedCount(for:),
            lastReadAt: effectiveLastReadAt(for:)
        )
    }

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 14, alignment: .top),
            count: options.options.columns
        )
    }

    private var gridCardHeight: CGFloat? {
        guard options.options.columns == 4 else { return nil }
        return options.options.layout == .cover ? 132 : 154
    }

    private func categoryLabel(_ name: String, id: UUID?) -> String {
        let count = collections.snapshot.library.filter { entry in id.map { entry.categoryIDs.contains($0) } ?? entry.categoryIDs.isEmpty }.count
        return options.options.showCounts ? "\(name)(\(count))" : name
    }

    @ViewBuilder private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            Text(categoryLabel("Default", id: nil)).tag(nil as UUID?)
            ForEach(collections.snapshot.categories) { category in
                Text(categoryLabel(category.name, id: category.id)).tag(Optional(category.id))
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if options.options.displaysCategories {
                    if collections.snapshot.categories.count <= 2 {
                        categoryPicker.pickerStyle(.segmented)
                    } else {
                        categoryPicker.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if !collections.isAccountScoped {
                    Text("Guest library • Sign in to sync across devices")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let error = collections.error {
                    CatalogueMessage(message: error) { collections.reload() }
                }
                if currentEntries.isEmpty {
                    ContentUnavailableView("No titles found", systemImage: "books.vertical", description: Text("Try another category or adjust your filters."))
                }
                if options.options.layout == .list {
                    LazyVStack(spacing: 18) { ForEach(currentEntries) { entry in entryLink(entry) } }
                } else {
                    LazyVGrid(columns: gridColumns, alignment: .center, spacing: 18) {
                        ForEach(currentEntries) { entry in entryLink(entry) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Library")
        .scrollEdgeEffectStyle(.soft, for: .top)
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search library"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    LibraryUpdatesCalendarView()
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Upcoming updates")
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingControls = true } label: { Image(systemName: "line.3.horizontal.decrease") }
                    .accessibilityLabel("Library display and filters")

                Button { showingCategories = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Edit categories")
            }
        }
        .sheet(isPresented: $showingControls) { LibraryControlsSheet().presentationDragIndicator(.visible) }
        .sheet(isPresented: $showingCategories) { LibraryCategoriesSheet().presentationDragIndicator(.visible) }
        .task { await environment.accountData.refreshCollections() }
        .refreshable { await environment.accountData.refreshCollections() }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            Task { await environment.accountData.refreshCollections() }
        }
        .onChange(of: collections.snapshot.categories) {
            if let id = selectedCategory, !collections.snapshot.categories.contains(where: { $0.id == id }) { selectedCategory = nil }
        }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            MangaDetailView(seed: seed, animation: animation, origin: .library)
        }
    }
    private func entryLink(_ entry: LibraryEntry) -> some View {
        NavigationLink(value: MangaDetailsSeed(item: entry.item)) {
            Group {
                if options.options.layout == .list {
                    HStack(spacing: 14) {
                        LibraryCard(item: entry.item, layout: .cover, height: 116).frame(width: 78, height: 116)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.item.title).font(.headline).lineLimit(2)
                            Text(entry.item.metadataLine).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                            if shouldShowBadges(for: entry) { badge(entry) }
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    LibraryCard(item: entry.item, layout: options.options.layout, height: gridCardHeight)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .top)
                        .overlay(alignment: .topLeading) {
                            if shouldShowBadges(for: entry) { badge(entry).padding(6) }
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .top)
        .matchedTransitionSource(id: entry.id, in: animation)
        .contextMenu {
            ForEach(collections.snapshot.categories) { category in
                Button {
                    collections.assign(category.id, entry: entry.id, included: !entry.categoryIDs.contains(category.id))
                } label: { Label(category.name, systemImage: entry.categoryIDs.contains(category.id) ? "checkmark.circle.fill" : "circle") }
            }
        }
    }

    private func downloadedCount(for entry: LibraryEntry) -> Int {
        guard let manga = entry.item.manga else { return entry.downloadedCount }
        return downloads.downloadedCount(for: manga.id)
    }

    private func effectiveLastReadAt(for entry: LibraryEntry) -> Date? {
        guard let mangaID = entry.item.manga?.id else { return entry.lastReadAt }
        let localLastReadAt = readingHistory.entries.lazy
            .filter { $0.manga.id == mangaID }
            .map(\.updatedAt)
            .max()
        return [entry.lastReadAt, localLastReadAt].compactMap { $0 }.max()
    }

    private func badge(_ entry: LibraryEntry) -> some View {
        let localDownloaded = downloadedCount(for: entry)
        return HStack(spacing: 6) {
            if options.options.displaysUnreadBadge, entry.unreadCount > 0 {
                badgePill(
                    "\(entry.unreadCount)",
                    systemImage: "book.closed",
                    color: Color(red: 0.22, green: 0.48, blue: 0.96),
                    accessibilityLabel: "\(entry.unreadCount) unread chapters"
                )
            }
            if options.options.displaysDownloadedBadge, localDownloaded > 0 {
                badgePill(
                    "\(localDownloaded)",
                    systemImage: "arrow.down",
                    color: Color(red: 0.20, green: 0.64, blue: 0.34),
                    accessibilityLabel: "\(localDownloaded) downloaded chapters on this device"
                )
            }
            if options.options.displaysLanguageBadge,
               let language = entry.item.manga?.language, !language.isEmpty {
                badgePill(
                    language.uppercased(),
                    color: Color(red: 0.80, green: 0.35, blue: 0.14),
                    accessibilityLabel: "Language: \(language)"
                )
            }
        }
        .lineLimit(1)
    }

    private func shouldShowBadges(for entry: LibraryEntry) -> Bool {
        (options.options.displaysUnreadBadge && entry.unreadCount > 0)
            || (options.options.displaysDownloadedBadge && downloadedCount(for: entry) > 0)
            || (options.options.displaysLanguageBadge && !(entry.item.manga?.language ?? "").isEmpty)
    }

    private func badgePill(
        _ text: String,
        systemImage: String? = nil,
        color: Color,
        accessibilityLabel: String
    ) -> some View {
        Group {
            if let systemImage {
                Label(text, systemImage: systemImage)
            } else {
                Text(text)
            }
        }
        .font(.caption2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(color, in: Capsule())
        .fixedSize()
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct LibraryCard: View {
    let item: ImageModel
    var layout: LibraryLayout = .compact
    var height: CGFloat? = nil

    private var coverHeight: CGFloat {
        height ?? (layout == .cover ? 180 : 210)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                CatalogueCover(
                    url: item.manga?.thumbnailURL,
                    referer: item.manga?.url,
                    asset: item.manga == nil ? item.image : nil
                )
                .frame(maxWidth: .infinity)
                .frame(height: coverHeight)
                if layout == .compact {
                    LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    Text(item.title)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if layout == .comfortable {
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        .accessibilityLabel(item.title)
    }
}

#Preview {
    @Previewable @Namespace var animation
    NavigationStack {
        LibraryView(animation: animation)
            .appEnvironment(.preview())
    }
}
