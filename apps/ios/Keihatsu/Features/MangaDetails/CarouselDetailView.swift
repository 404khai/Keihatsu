import SwiftUI

struct CarouselDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let seed: MangaDetailsSeed
    let animation: Namespace.ID
    let origin: ReaderLaunchContext.Origin

    init(item: ImageModel, animation: Namespace.ID, origin: ReaderLaunchContext.Origin = .details) {
        seed = MangaDetailsSeed(item: item)
        self.animation = animation
        self.origin = origin
    }

    init(seed: MangaDetailsSeed, animation: Namespace.ID, origin: ReaderLaunchContext.Origin = .details) {
        self.seed = seed
        self.animation = animation
        self.origin = origin
    }

    var body: some View {
        MangaDetailsContentView(
            seed: seed,
            animation: animation,
            origin: origin,
            repository: environment.services.mangaDetails,
            allowsFixtureLibraryActions: environment.services.isPreview
        )
    }
}

private struct MangaDetailsContentView: View {
    @EnvironmentObject private var collections: CollectionStore
    @StateObject private var model: MangaDetailsViewModel
    let animation: Namespace.ID
    let allowsFixtureLibraryActions: Bool

    @State private var showCategorySheet = false
    @State private var showFilterSheet = false
    @State private var showCollapsedHeader = false
    @State private var selectedCategories = Set<UUID>()
    @State private var selectedReader: ReaderLaunchContext?
    @State private var showAccountRequired = false

    private var sourceURL: URL? {
        guard let url = model.manga.url, ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }

    init(
        seed: MangaDetailsSeed,
        animation: Namespace.ID,
        origin: ReaderLaunchContext.Origin,
        repository: any MangaDetailsRepository,
        allowsFixtureLibraryActions: Bool
    ) {
        _model = StateObject(wrappedValue: MangaDetailsViewModel(seed: seed, origin: origin, repository: repository))
        self.animation = animation
        self.allowsFixtureLibraryActions = allowsFixtureLibraryActions
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                VStack(alignment: .leading, spacing: 28) {
                    overviewSection
                    chapterSection
                    recommendationsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 44)
            }
        }
        .coordinateSpace(name: "detailScroll")
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(showCollapsedHeader ? .visible : .hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onPreferenceChange(HeroHeaderVisibilityKey.self) { showCollapsedHeader = $0 < 50 }
        .task(id: model.seed.manga.id) { await model.load() }
        .refreshable { await model.refreshAll() }
        .toolbar { detailToolbar }
        .sheet(isPresented: $showCategorySheet) {
            categorySheet.presentationDetents([.height(340)]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFilterSheet) {
            filterSheet.presentationDetents([.height(330)]).presentationDragIndicator(.visible)
        }
        .alert("Account required", isPresented: $showAccountRequired) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Sign in when account support is available to add titles to your library and categories.")
        }
        .navigationDestination(item: $selectedReader) { context in
            ReaderEntryView(manga: model.manga, chapters: model.chapters, context: context)
        }
        .navigationDestination(for: MangaDetailsSeed.self) { seed in
            CarouselDetailView(seed: seed, animation: animation, origin: .details)
        }
    }

    @ToolbarContentBuilder private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(model.manga.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .opacity(showCollapsedHeader ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showCollapsedHeader)
                .accessibilityIdentifier("manga.details.title")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if let shareURL = sourceURL {
                ShareLink(item: shareURL) { Image(systemName: "square.and.arrow.up") }
            }
            Button { showFilterSheet = true } label: {
                Image(systemName: model.activeFilterCount == 0 ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel("Filter chapters")
            Menu {
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await model.refreshAll() } }
                if let sourceURL { Link("View on source", destination: sourceURL) }
            } label: { Image(systemName: "ellipsis") }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            CatalogueCover(url: model.manga.thumbnailURL, referer: model.manga.url, asset: model.seed.coverAsset)
                .frame(maxWidth: .infinity)
                .frame(height: 620)
                .overlay {
                    LinearGradient(colors: [.black.opacity(0.02), .black.opacity(0.12), .black.opacity(0.55), .black], startPoint: .top, endPoint: .bottom)
                }
                .navigationTransition(.zoom(sourceID: model.seed.transitionID, in: animation))
                .modifier(BackgroundExtensionModifier())

            VStack(alignment: .leading, spacing: 10) {
                Text(model.manga.title.uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let author = model.manga.author, !author.isEmpty { metadataLine(author, icon: "person.fill") }
                if let artist = model.manga.artist, !artist.isEmpty { metadataLine(artist, icon: "paintbrush.pointed.fill") }
                metadataLine(model.manga.id.sourceID.uppercased(), icon: "puzzlepiece.extension.fill")

                HStack(spacing: 14) {
                    Button {
                        if allowsFixtureLibraryActions { showCategorySheet = true }
                        else { showAccountRequired = true }
                    } label: {
                        Label("Add to Library", systemImage: "book.closed.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .frame(height: 52)
                            .background(.white, in: Capsule())
                    }
                    .glassEffect(.regular, in: .capsule)

                    Button { openResumeChapter() } label: {
                        Image(systemName: "play.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                    }
                    .disabled(model.resumeChapter == nil)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel(model.resumeChapter?.hasHistory == true ? "Resume reading" : "Read now")
                    .accessibilityIdentifier("manga.details.read")
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: HeroHeaderVisibilityKey.self, value: proxy.frame(in: .named("detailScroll")).minY)
            }
        }
    }

    private func metadataLine(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 15))
            .foregroundStyle(.white.opacity(0.85))
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overview").font(.title3.weight(.semibold)).foregroundStyle(.white)
                if model.metadataLoading { ProgressView().tint(.white).controlSize(.small) }
            }
            if let description = model.manga.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(model.showsFullDescription ? nil : 5)
                    .onTapGesture { withAnimation { model.showsFullDescription.toggle() } }
                if description.count > 220 {
                    Button(model.showsFullDescription ? "Show less" : "Read more") { withAnimation { model.showsFullDescription.toggle() } }
                        .font(.subheadline.weight(.semibold))
                }
            } else {
                Text("No description available.").foregroundStyle(.white.opacity(0.62))
            }
            if !model.manga.genres.isEmpty {
                Text(model.manga.genres.joined(separator: " • ")).font(.footnote).foregroundStyle(.white.opacity(0.6))
            }
            if let error = model.metadataError {
                InlineDetailError(message: error) { Task { await model.refreshMetadata() } }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chapterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Chapters").font(.title3.weight(.semibold)).foregroundStyle(.white)
                Text("\(model.filteredChapters.count)").font(.subheadline).foregroundStyle(.white.opacity(0.55)).monospacedDigit()
                Spacer()
                if model.chaptersLoading { ProgressView().tint(.white).controlSize(.small) }
            }
            if let error = model.chaptersError {
                InlineDetailError(message: error) { Task { await model.refreshChapters() } }
            }
            if !model.chaptersLoading && model.filteredChapters.isEmpty {
                ContentUnavailableView {
                    Label(model.chapters.isEmpty ? "No chapters" : "No matching chapters", systemImage: "text.book.closed")
                } description: {
                    Text(model.chapters.isEmpty ? "This source has not returned any chapters." : "Change or clear the active filters.")
                }
                .foregroundStyle(.white)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(model.displayedChapters) { chapter in
                        chapterRow(chapter)
                        if chapter.id != model.displayedChapters.last?.id { Divider().overlay(.white.opacity(0.08)) }
                    }
                }
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1) }

                if model.filteredChapters.count > 3 {
                    Button(model.showsAllChapters ? "Show latest three" : "Show all chapters") {
                        withAnimation { model.showsAllChapters.toggle() }
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            }
        }
    }

    private func chapterRow(_ chapter: Chapter) -> some View {
        let state = model.state(for: chapter)
        return Button { open(chapter) } label: {
            HStack(spacing: 12) {
                if state.isBookmarked { Image(systemName: "bookmark.fill").foregroundStyle(.tint) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.name).font(.headline).foregroundStyle(state.isRead ? .white.opacity(0.45) : .white)
                    HStack(spacing: 6) {
                        if let date = chapter.uploadedAt { Text(date.formatted(date: .abbreviated, time: .omitted)) }
                        if let scanlator = chapter.scanlator, !scanlator.isEmpty { Text("• \(scanlator)") }
                    }
                    .font(.subheadline)
                    .foregroundStyle(state.isRead ? .white.opacity(0.35) : .white.opacity(0.62))
                }
                Spacer()
                if state.isDownloaded { Image(systemName: "arrow.down.circle.fill").foregroundStyle(.secondary) }
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { Task { await model.toggleBookmark(chapter) } } label: {
                Label(state.isBookmarked ? "Unbookmark" : "Bookmark", systemImage: state.isBookmarked ? "bookmark.slash" : "bookmark")
            }.tint(.accentColor)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button { Task { await model.toggleRead(chapter) } } label: {
                Label(state.isRead ? "Mark Unread" : "Mark Read", systemImage: state.isRead ? "circle" : "checkmark.circle.fill")
            }.tint(state.isRead ? .gray : .green)
        }
    }

    @ViewBuilder private var recommendationsSection: some View {
        if model.recommendationsLoading || model.recommendationsError != nil || !model.recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("You may also like").font(.title3.weight(.semibold)).foregroundStyle(.white)
                    if model.recommendationsLoading { ProgressView().tint(.white).controlSize(.small) }
                }
                if let error = model.recommendationsError {
                    InlineDetailError(message: error) { Task { await model.refreshRecommendations() } }
                }
                if !model.recommendations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            ForEach(model.recommendations) { manga in
                                NavigationLink(value: MangaDetailsSeed(manga: manga)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        CatalogueCover(url: manga.thumbnailURL, referer: manga.url)
                                            .frame(width: 126, height: 184)
                                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        Text(manga.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(2).frame(width: 126, alignment: .leading)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var categorySheet: some View {
        NavigationStack {
            List(selection: $selectedCategories) {
                Text("Default")
                ForEach(collections.snapshot.categories) { category in Text(category.name).tag(category.id) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Select Categories")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button("Add to Library") { showCategorySheet = false }
                    .buttonStyle(.borderedProminent).controlSize(.large).padding()
            }
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Toggle("Downloaded", isOn: $model.filter.downloaded)
                Toggle("Unread", isOn: $model.filter.unread)
                Toggle("Bookmarked", isOn: $model.filter.bookmarked)
                if model.activeFilterCount > 0 {
                    Button("Clear Filters", role: .destructive) { model.filter = ChapterFilter() }
                }
            }
            .navigationTitle("Filter Chapters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func openResumeChapter() {
        guard let resume = model.resumeChapter else { return }
        open(resume.chapter, pageIndex: resume.pageIndex)
    }

    private func open(_ chapter: Chapter, pageIndex: Int? = nil) {
        Task { selectedReader = await model.readerContext(for: chapter, pageIndex: pageIndex) }
    }
}

private struct InlineDetailError: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(message).font(.footnote).foregroundStyle(.white.opacity(0.62))
            Spacer()
            Button("Retry", action: retry).font(.footnote.weight(.semibold))
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HeroHeaderVisibilityKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct BackgroundExtensionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) { content.backgroundExtensionEffect() } else { content }
    }
}

#Preview {
    @Previewable @Namespace var animation
    NavigationStack { CarouselDetailView(item: images[4], animation: animation, origin: .home) }
        .appEnvironment(.preview())
}
