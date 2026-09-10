import SwiftUI

struct LibraryView: View {
    let animation: Namespace.ID
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var collections: CollectionStore
    @EnvironmentObject private var options: LibraryOptionsStore
    @EnvironmentObject private var downloads: DownloadCoordinator
    @State private var selectedCategory: UUID?
    @State private var searchText = ""
    @State private var showingControls = false
    @State private var showingCategories = false

    private var currentEntries: [LibraryEntry] {
        options.options.filtered(collections.snapshot.library, category: selectedCategory, query: searchText)
    }

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 14, alignment: .top),
            count: options.options.columns
        )
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
            CarouselDetailView(seed: seed, animation: animation, origin: .library)
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
                    LibraryCard(item: entry.item, layout: options.options.layout)
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

    private func badge(_ entry: LibraryEntry) -> some View {
        let localDownloaded = entry.item.manga.map { downloads.downloadedCount(for: $0.id) } ?? 0
        return HStack(spacing: 6) {
            if options.options.displaysUnreadBadge {
                Label("\(entry.unreadCount)", systemImage: "book.closed")
            }
            if options.options.displaysDownloadedBadge {
                Label("\(localDownloaded)", systemImage: "arrow.down")
            }
            if options.options.displaysLanguageBadge,
               let language = entry.item.manga?.language, !language.isEmpty {
                Text(language.uppercased())
            }
        }
        .font(.caption2).monospacedDigit().lineLimit(1)
        .padding(5).background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.unreadCount) unread chapters, \(localDownloaded) downloaded chapters on this device")
    }

    private func shouldShowBadges(for entry: LibraryEntry) -> Bool {
        options.options.displaysUnreadBadge
            || options.options.displaysDownloadedBadge
            || (options.options.displaysLanguageBadge && !(entry.item.manga?.language ?? "").isEmpty)
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
