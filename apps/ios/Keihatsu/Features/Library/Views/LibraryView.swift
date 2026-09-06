import SwiftUI

struct LibraryView: View {
    let animation: Namespace.ID
    @EnvironmentObject private var collections: CollectionStore
    @EnvironmentObject private var options: LibraryOptionsStore
    @State private var selectedCategory: UUID?
    @State private var searchText = ""
    @State private var showingControls = false
    @State private var showingCategories = false

    private var currentEntries: [LibraryEntry] {
        options.options.filtered(collections.snapshot.library, category: selectedCategory, query: searchText)
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
                if collections.snapshot.categories.count <= 2 {
                    categoryPicker.pickerStyle(.segmented)
                } else {
                    categoryPicker.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("Sample library • Account sync coming soon")
                    .font(.caption).foregroundStyle(.secondary)
                if let error = collections.error {
                    CatalogueMessage(message: error) { collections.reload() }
                }
                if currentEntries.isEmpty {
                    ContentUnavailableView("No titles found", systemImage: "books.vertical", description: Text("Try another category or adjust your filters."))
                }
                if options.options.layout == .list {
                    LazyVStack(spacing: 18) { ForEach(currentEntries) { entry in entryLink(entry) } }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: options.options.columns), spacing: 18) {
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
                Button { showingControls = true } label: { Image(systemName: "line.3.horizontal.decrease") }
                    .accessibilityLabel("Library display and filters")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingCategories = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Edit categories")
            }
        }
        .sheet(isPresented: $showingControls) { LibraryControlsSheet().presentationDragIndicator(.visible) }
        .sheet(isPresented: $showingCategories) { LibraryCategoriesSheet().presentationDragIndicator(.visible) }
        .onChange(of: collections.snapshot.categories) {
            if let id = selectedCategory, !collections.snapshot.categories.contains(where: { $0.id == id }) { selectedCategory = nil }
        }
        .navigationDestination(for: ImageModel.self) { item in
            CarouselDetailView(item: item, animation: animation)
        }
    }
    private func entryLink(_ entry: LibraryEntry) -> some View {
        NavigationLink(value: entry.item) {
            Group {
                if options.options.layout == .list {
                    HStack(spacing: 14) {
                        LibraryCard(item: entry.item, layout: .cover, height: 116).frame(width: 78, height: 116)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.item.title).font(.headline).lineLimit(2)
                            Text(entry.item.metadataLine).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                            if options.options.showBadges { badge(entry) }
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    LibraryCard(item: entry.item, layout: options.options.layout)
                        .overlay(alignment: .topLeading) {
                            if options.options.showBadges { badge(entry).padding(6) }
                        }
                }
            }
        }
        .buttonStyle(.plain)
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
        HStack(spacing: 6) {
            Label("\(entry.unreadCount)", systemImage: "book.closed")
            Label("\(entry.downloadedCount)", systemImage: "arrow.down")
        }
        .font(.caption2).monospacedDigit().lineLimit(1)
        .padding(5).background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.unreadCount) unread chapters, \(entry.downloadedCount) downloaded chapters")
    }
}

private struct LibraryCard: View {
    let item: ImageModel
    var layout: LibraryLayout = .compact
    var height: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                Image(item.image).resizable().aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity).frame(height: height ?? (layout == .cover ? 180 : 210)).clipped()
                if layout == .compact {
                    LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    Text(item.title).font(.system(size: 15)).foregroundStyle(.white).lineLimit(2).padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if layout == .comfortable { Text(item.title).font(.subheadline).lineLimit(2) }
        }
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
