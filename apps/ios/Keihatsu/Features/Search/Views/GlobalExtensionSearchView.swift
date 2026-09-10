import SwiftUI

struct GlobalExtensionSearchView: View {
    @State private var searchText = ""
    @State private var selectedTab: SearchExtensionTab = .pinned
    @State private var showingFilters = false

    @EnvironmentObject private var sources: SourcePreferencesStore
    @EnvironmentObject private var model: SearchViewModel
    @EnvironmentObject private var navigation: AppNavigation
    @Namespace private var animation
    @State private var excludedSources: Set<String> = []

    private var visibleExtensions: [Source] {
        sources.enabledSources.filter { (selectedTab == .all || sources.isPinned($0)) && !excludedSources.contains($0.id) }
    }
    private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var searchKey: String { searchText + "|" + visibleExtensions.map(\.id).joined(separator: ",") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Picker("Sources", selection: $selectedTab) {
                    ForEach(SearchExtensionTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if sources.isLoading { ProgressView("Loading sources…") }
                if let error = sources.error {
                    CatalogueMessage(message: error) { Task { await sources.load(force: true) } }
                }
                if visibleExtensions.isEmpty && !sources.isLoading {
                    ContentUnavailableView {
                        Label("No sources selected", systemImage: "magnifyingglass")
                    } description: { Text("Choose All, adjust filters, or enable a source in Plugins.") }
                    actions: { Button("Manage Sources") { navigation.selectedTab = .extensions } }
                }
                if isSearching {
                    searchResults
                } else {
                    if !model.recentQueries.isEmpty {
                        HStack {
                            Text("Recent searches").font(.headline)
                            Spacer()
                            Button("Clear") { model.clearHistory() }
                        }
                        ForEach(model.recentQueries, id: \.self) { query in
                            Button { searchText = query } label: { Label(query, systemImage: "clock") }
                        }
                    }
                    sourceList
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task { await sources.load() }
        .task(id: searchKey) { await model.search(searchText, sources: visibleExtensions) }
        .onSubmit(of: .search) { model.remember(searchText) }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            CarouselDetailView(seed: seed, animation: animation, origin: .search)
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search across sources"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSourcesSheet(sources: sources.enabledSources, excluded: $excludedSources)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var sourceList: some View {
        VStack(spacing: 12) {
            ForEach(visibleExtensions) { source in
                HStack(spacing: 14) {
                    CatalogueCover(url: source.iconURL)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(source.language.uppercased() + " • " + (source.baseURL?.absoluteString ?? ""))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if sources.isPinned(source) {
                        Image(systemName: "pin.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                }
            }
        }
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(model.sections) { section in
                let source = section.source
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        CatalogueCover(url: source.iconURL)
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(source.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    let results = section.mangas.map(ImageModel.init(manga:))
                    if section.isLoading { ProgressView() }
                    if let error = section.error {
                        CatalogueMessage(message: error) { Task { await model.retry(source.id) } }
                    }

                    if results.isEmpty && !section.isLoading && section.error == nil {
                        Text("No results found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 14) {
                                ForEach(results) { item in
                                    NavigationLink(value: MangaDetailsSeed(item: item)) {
                                        GlobalSearchMangaCard(item: item)
                                    }.buttonStyle(.plain)
                                    .matchedTransitionSource(id: item.id, in: animation)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        if section.hasNextPage && section.error == nil {
                            Button("Load more") { Task { await model.loadMore(source.id) } }
                                .disabled(section.isLoading)
                        }
                    }
                }
            }
        }
    }
}

private struct GlobalSearchMangaCard: View {
    let item: ImageModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CatalogueCover(url: item.manga?.thumbnailURL, referer: item.manga?.url, asset: item.manga == nil ? item.image : nil)
                .frame(width: 132, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(12)
        }
        .frame(width: 132, height: 190)
    }
}

private enum SearchExtensionTab: CaseIterable, Identifiable {
    case pinned
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .pinned: return "Pinned"
        case .all: return "All"
        }
    }
}

private struct FilterSourcesSheet: View {
    let sources: [Source]
    @Binding var excluded: Set<String>

    var body: some View {
        NavigationStack {
            List(sources) { source in
                HStack(spacing: 14) {
                    CatalogueCover(url: source.iconURL)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)

                        Text(source.language.uppercased() + " • " + (source.baseURL?.absoluteString ?? ""))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                Toggle("Search \(source.name)", isOn: Binding(get: { !excluded.contains(source.id) }, set: { value in
                    if value { excluded.remove(source.id) } else { excluded.insert(source.id) }
                }))
            }
            .navigationTitle("Filter Sources")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        GlobalExtensionSearchView()
            .appEnvironment(.preview())
    }
}
