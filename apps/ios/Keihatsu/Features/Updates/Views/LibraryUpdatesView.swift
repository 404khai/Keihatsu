import SwiftUI

struct LibraryUpdatesView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let animation: Namespace.ID

    var body: some View {
        LibraryUpdatesContentView(
            animation: animation,
            repository: environment.services.mangaDetails
        )
    }
}

private struct LibraryUpdatesContentView: View {
    @Environment(\.keihatsuTheme) private var theme
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var collections: CollectionStore
    @EnvironmentObject private var history: ReadingHistoryModel
    @EnvironmentObject private var downloads: DownloadCoordinator
    @StateObject private var model: LibraryUpdatesViewModel
    let animation: Namespace.ID

    init(animation: Namespace.ID, repository: any MangaDetailsRepository) {
        self.animation = animation
        _model = StateObject(wrappedValue: LibraryUpdatesViewModel(repository: repository))
    }

    private var groups: [LibraryUpdateDay] {
        model.groups(isDownloaded: downloads.isDownloaded(_:))
    }

    var body: some View {
        Group {
            if groups.isEmpty, !model.isLoading {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: "calendar.badge.clock")
                } description: {
                    Text(model.errorMessage ?? emptyDescription)
                } actions: {
                    Button("Refresh") { Task { await refresh() } }
                }
            } else {
                List {
                    Section {
                        HStack(spacing: 8) {
                            if model.isLoading { ProgressView().controlSize(.small) }
                            Text(lastUpdatedLabel)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(groups) { group in
                        Section(group.date.formatted(.dateTime.day().month(.abbreviated).year())) {
                            ForEach(group.items) { item in updateRow(item) }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { await refresh() }
            }
        }
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter", selection: $model.filter) {
                        ForEach(LibraryUpdateFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    Image(systemName: model.filter == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel("Filter updates")

                NavigationLink {
                    LibraryUpdatesCalendarView(model: model, animation: animation)
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Upcoming releases")
            }
        }
        .task {
            await history.refresh()
            await model.load(entries: collections.snapshot.library, history: history.chapterEntries, forceRefresh: false)
            if model.items.isEmpty { await refresh() }
        }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            MangaDetailView(seed: seed, animation: animation, origin: .library)
        }
    }

    private var emptyTitle: String {
        model.filter == .all ? "No Chapter Updates" : "No Matching Updates"
    }

    private var emptyDescription: String {
        model.filter == .all
            ? "Pull to refresh after adding titles to your library."
            : "Choose another filter or refresh your library."
    }

    private var lastUpdatedLabel: String {
        guard let date = model.lastUpdatedAt else { return "Pull to check for new chapters" }
        return "Updated \(date.formatted(.relative(presentation: .named)))"
    }

    private func refresh() async {
        await environment.accountData.refreshCollections()
        await history.refreshFromAccount()
        await model.load(entries: collections.snapshot.library, history: history.chapterEntries, forceRefresh: true)
    }

    private func updateRow(_ item: LibraryUpdateItem) -> some View {
        HStack(spacing: 14) {
            NavigationLink(value: MangaDetailsSeed(manga: item.manga, coverAsset: item.coverAsset)) {
                HStack(spacing: 14) {
                CatalogueCover(
                    url: item.manga.thumbnailURL,
                    referer: item.manga.url,
                    asset: item.coverAsset
                )
                .frame(width: 54, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.manga.title)
                        .font(.headline)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Circle().fill(theme.colors.accent).frame(width: 7, height: 7)
                        Text(item.chapter.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            downloadControl(item)
        }
        .padding(.vertical, 5)
        .opacity(item.state.isRead ? 0.46 : 1)
        .accessibilityIdentifier("library.update.\(item.chapter.id.chapterID)")
    }

    @ViewBuilder private func downloadControl(_ item: LibraryUpdateItem) -> some View {
        let status = downloads.status(for: item.chapter.id)
        if status == .completed {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(theme.colors.accent)
                .accessibilityLabel("Downloaded")
        } else if status?.isActive == true {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Downloading")
        } else {
            Button {
                downloads.enqueue(manga: item.manga, chapters: [item.chapter], extensionName: item.manga.id.sourceID)
            } label: {
                Image(systemName: status == nil ? "arrow.down.circle" : "arrow.clockwise.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(status == nil ? "Download chapter" : "Retry download")
        }
    }
}

#Preview {
    @Previewable @Namespace var animation
    NavigationStack {
        LibraryUpdatesView(animation: animation)
            .appEnvironment(.preview())
    }
}
