import SwiftUI

struct GlobalExtensionSearchView: View {
    @State private var searchText = ""
    @State private var selectedTab: SearchExtensionTab = .pinned
    @State private var showingFilters = false

    private let extensions = SearchExtensionSource.installedSources

    private var visibleExtensions: [SearchExtensionSource] {
        switch selectedTab {
        case .pinned:
            return extensions.filter(\.isPinned)
        case .all:
            return extensions
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var searchResultExtensions: [SearchExtensionSource] {
        visibleExtensions.sorted { lhs, rhs in
            let lhsHasResults = !lhs.results(for: searchText).isEmpty
            let rhsHasResults = !rhs.results(for: searchText).isEmpty

            if lhsHasResults != rhsHasResults {
                return lhsHasResults && !rhsHasResults
            }

            return lhs.name < rhs.name
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Picker("Sources", selection: $selectedTab) {
                    ForEach(SearchExtensionTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if isSearching {
                    searchResults
                } else {
                    sourceList
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
            FilterSourcesSheet(sources: SearchExtensionSource.allFilterSources)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var sourceList: some View {
        VStack(spacing: 12) {
            ForEach(visibleExtensions) { source in
                HStack(spacing: 14) {
                    Image(source.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(source.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if source.isPinned {
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
            ForEach(searchResultExtensions) { source in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(source.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(source.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    let results = source.results(for: searchText)

                    if results.isEmpty {
                        Text("No results found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(results) { item in
                                    GlobalSearchMangaCard(item: item)
                                }
                            }
                            .padding(.vertical, 2)
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
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
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
    let sources: [SearchExtensionSource]

    var body: some View {
        NavigationStack {
            List(sources) { source in
                HStack(spacing: 14) {
                    Image(source.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)

                        Text(source.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Filter Sources")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SearchExtensionSource: Identifiable {
    let id = UUID()
    let name: String
    let assetName: String
    let subtitle: String
    let isPinned: Bool

    func results(for query: String) -> [ImageModel] {
        if name == "Atsumaru" || name == "BatCave" {
            return []
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return images }

        return images.filter { item in
            item.title.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    static let installedSources = [
        SearchExtensionSource(name: "Atsumaru", assetName: "atsumaru", subtitle: "EN • https://atsumaru.example", isPinned: true),
        SearchExtensionSource(name: "ManhuaTop", assetName: "manhuatop", subtitle: "EN • https://manhuatop.example", isPinned: true),
        SearchExtensionSource(name: "WeebCentral", assetName: "weebcentral", subtitle: "EN • https://weebcentral.example", isPinned: true)
    ]

    static let allFilterSources = installedSources + [
        SearchExtensionSource(name: "BatCave", assetName: "batcave", subtitle: "EN • https://batcave.example", isPinned: false)
    ]
}

#Preview {
    NavigationStack {
        GlobalExtensionSearchView()
    }
}
