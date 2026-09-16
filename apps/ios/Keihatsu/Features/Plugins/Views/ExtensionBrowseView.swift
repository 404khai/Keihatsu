import SwiftUI

struct ExtensionBrowseView: View {
    let source: Source

    @EnvironmentObject private var collections: CollectionStore
    @StateObject private var model: ExtensionBrowseViewModel
    @State private var searchText = ""
    @State private var layout: ExtensionBrowseLayout = .comfortable
    @State private var showsCompactTitle = false
    @Namespace private var animation

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: 10, alignment: .top),
        count: 3
    )

    init(source: Source, repository: any CatalogueRepository) {
        self.source = source
        _model = StateObject(wrappedValue: ExtensionBrowseViewModel(source: source, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sourceHeader

                if model.mangas.isEmpty, model.isLoading {
                    ProgressView("Loading manga…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else if model.mangas.isEmpty, let error = model.error {
                    ContentUnavailableView {
                        Label("Couldn’t load manga", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await model.reload(query: searchText) } }
                    }
                    .padding(.top, 44)
                } else if model.mangas.isEmpty {
                    ContentUnavailableView(
                        "No manga found",
                        systemImage: "books.vertical",
                        description: Text("Try a different search.")
                    )
                    .padding(.top, 44)
                } else if layout == .list {
                    LazyVStack(spacing: 12) {
                        ForEach(model.mangas) { manga in
                            mangaLink(manga) { ExtensionMangaListCard(manga: manga, isInLibrary: isInLibrary(manga)) }
                                .onAppear { loadMoreIfNeeded(manga) }
                        }
                    }
                } else {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                        ForEach(model.mangas) { manga in
                            mangaLink(manga) {
                                ExtensionMangaGridCard(
                                    manga: manga,
                                    layout: layout,
                                    isInLibrary: isInLibrary(manga)
                                )
                            }
                            .onAppear { loadMoreIfNeeded(manga) }
                        }
                    }
                }

                if !model.mangas.isEmpty, model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else if !model.mangas.isEmpty, model.error != nil {
                    Button("Retry loading more", systemImage: "arrow.clockwise") {
                        Task { await model.loadNextPage() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 44
        } action: { _, shouldShow in
            guard shouldShow != showsCompactTitle else { return }
            withAnimation(.snappy(duration: 0.25)) {
                showsCompactTitle = shouldShow
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search \(source.name)"))
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if showsCompactTitle {
                    compactTitle
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if let website = source.baseURL {
                    Link(destination: website) {
                        Image(systemName: "safari")
                    }
                    .accessibilityLabel("Open \(source.name) in browser")
                }

                Menu {
                    Picker("Appearance", selection: $layout) {
                        ForEach(ExtensionBrowseLayout.allCases) { option in
                            Label(option.title, systemImage: option.systemImage).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .accessibilityLabel("Change appearance")
            }
            DefaultToolbarItem(
                kind: .search,
                placement: .bottomBar
            )
        }
        .task(id: searchText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            if !searchText.isEmpty {
                try? await Task.sleep(for: .milliseconds(350))
            }
            guard !Task.isCancelled else { return }
            await model.reload(query: searchText)
        }
        .refreshable { await model.reload(query: searchText) }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            MangaDetailView(seed: seed, animation: animation, origin: .search)
        }
    }

    private var sourceHeader: some View {
        HStack(spacing: 12) {
            ExtensionImageView(sourceID: source.id, url: source.iconURL, size: 58, cornerRadius: 15)

            VStack(alignment: .leading, spacing: 3) {
                Text(source.name)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                Text(source.language.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactTitle: some View {
        HStack(spacing: 8) {
            ExtensionImageView(sourceID: source.id, url: source.iconURL, size: 28, cornerRadius: 7)
            Text(source.name)
                .font(.headline)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func mangaLink<Content: View>(_ manga: Manga, @ViewBuilder content: () -> Content) -> some View {
        NavigationLink(value: MangaDetailsSeed(manga: manga)) {
            content()
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: MangaDetailsSeed(manga: manga).transitionID, in: animation)
    }

    private func isInLibrary(_ manga: Manga) -> Bool {
        collections.libraryEntry(for: manga.id) != nil
    }

    private func loadMoreIfNeeded(_ manga: Manga) {
        guard manga.id == model.mangas.last?.id, model.hasNextPage else { return }
        Task { await model.loadNextPage() }
    }
}

private enum ExtensionBrowseLayout: String, CaseIterable, Identifiable {
    case comfortable
    case compact
    case list

    var id: Self { self }

    var title: String {
        switch self {
        case .comfortable: "Comfortable grid"
        case .compact: "Compact grid"
        case .list: "List"
        }
    }

    var systemImage: String {
        switch self {
        case .comfortable: "square.grid.3x3"
        case .compact: "rectangle.grid.3x2"
        case .list: "list.bullet"
        }
    }
}

private struct ExtensionMangaGridCard: View {
    let manga: Manga
    let layout: ExtensionBrowseLayout
    let isInLibrary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .bottomLeading) {
                CatalogueCover(url: manga.thumbnailURL, referer: manga.url)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(2 / 3, contentMode: .fit)

                if layout == .compact {
                    LinearGradient(colors: [.clear, .black.opacity(0.86)], startPoint: .top, endPoint: .bottom)
                    Text(manga.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(8)
                }

                if isInLibrary {
                    Color.black.opacity(0.45)
                    LibraryCoverMarker()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if layout == .comfortable {
                Text(manga.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityLabel(manga.title + (isInLibrary ? ", in library" : ""))
    }
}

private struct ExtensionMangaListCard: View {
    let manga: Manga
    let isInLibrary: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                CatalogueCover(url: manga.thumbnailURL, referer: manga.url)
                    .frame(width: 62, height: 92)
                if isInLibrary {
                    Color.black.opacity(0.45)
                    LibraryCoverMarker(compact: true)
                        .padding(5)
                }
            }
            .frame(width: 62, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(manga.author?.isEmpty == false ? manga.author! : manga.status ?? "Manga")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if isInLibrary {
                    Label("In Library", systemImage: "book.closed.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct LibraryCoverMarker: View {
    var compact = false

    var body: some View {
        Image(systemName: "book.closed.fill")
            .font(.system(size: compact ? 11 : 14, weight: .bold))
            .foregroundStyle(Color.black.opacity(0.72))
            .padding(compact ? 5 : 7)
            .background(Color(red: 1, green: 0.7, blue: 0.42), in: RoundedRectangle(cornerRadius: compact ? 5 : 7))
    }
}
