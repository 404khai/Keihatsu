import SwiftUI
import UIKit

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @StateObject private var model: ReaderViewModel
    @State private var showsComments = false
    private let imagePipeline: ImagePipeline

    init(
        manga: Manga,
        chapters: [Chapter],
        context: ReaderLaunchContext,
        reader: any ReaderRepository,
        history: ReadingHistoryModel,
        imagePipeline: ImagePipeline,
        incognito: Bool
    ) {
        self.imagePipeline = imagePipeline
        _model = StateObject(wrappedValue: ReaderViewModel(
            manga: manga,
            chapters: chapters,
            context: context,
            reader: reader,
            history: history,
            imagePipeline: imagePipeline,
            incognito: incognito
        ))
    }

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ZStack {
                    readerBackground.ignoresSafeArea()
                    content(viewport: viewport)

                    if model.controlsVisible {
                        ReaderChrome(
                            title: model.manga.title,
                            chapterName: model.currentChapter?.name ?? "Reader",
                            page: model.displayedPage,
                            pageCount: model.currentPages.count,
                            isBookmarked: model.isBookmarked,
                            isIncognito: preferencesStore.preferences.incognitoModeEnabled,
                            canOpenOlder: model.hasOlderChapter,
                            canOpenNewer: model.hasNewerChapter,
                            onDismiss: { dismiss() },
                            onBookmark: { Task { await model.toggleBookmark() } },
                            onComments: { showsComments = true },
                            onOlder: { Task { await model.openOlderChapter() } },
                            onNewer: { Task { await model.openNewerChapter() } },
                            onScrub: { model.scrub(to: $0) }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .onPreferenceChange(ReaderPageFrameKey.self) { frames in
                    updateVisiblePage(frames, viewportHeight: viewport.size.height)
                }
                .onChange(of: model.scrollRequest) { _, request in
                    guard let request else { return }
                    scroll(request, with: proxy)
                }
                .task {
                    await model.load()
                    if let request = model.scrollRequest { scroll(request, with: proxy, animated: false) }
                }
            }
        }
        .background(readerBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!model.controlsVisible)
        .persistentSystemOverlays(model.controlsVisible ? .automatic : .hidden)
        .sheet(isPresented: $showsComments) {
            ReaderCommentsSheet(chapterName: model.currentChapter?.name ?? "Chapter")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { updateIdleTimer() }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Task { await model.end() }
        }
        .onChange(of: preferencesStore.preferences.keepScreenAwake) { updateIdleTimer() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.resume()
                updateIdleTimer()
            case .inactive, .background:
                UIApplication.shared.isIdleTimerDisabled = false
                Task { await model.suspend() }
            @unknown default:
                break
            }
        }
        .accessibilityIdentifier("reader.entry")
    }

    @ViewBuilder
    private func content(viewport: GeometryProxy) -> some View {
        if model.isLoading && model.loadedChapters.isEmpty {
            ProgressView("Loading chapter…")
                .tint(.white)
                .foregroundStyle(.white)
        } else if let error = model.loadError, model.loadedChapters.isEmpty {
            ReaderFailureView(message: error) { Task { await model.retryLoad() } }
        } else if model.loadedChapters.isEmpty {
            ContentUnavailableView("No pages found", systemImage: "photo.stack", description: Text("This chapter did not return readable pages."))
                .foregroundStyle(.white)
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.loadedChapters.enumerated()), id: \.element.id) { chapterIndex, loaded in
                        if chapterIndex > 0 {
                            ReaderChapterBoundary(
                                previous: model.loadedChapters[chapterIndex - 1].chapter.name,
                                next: loaded.chapter.name
                            )
                        }
                        ForEach(loaded.pages) { page in
                            ReaderPageView(page: page, pipeline: imagePipeline)
                                .id(page.id)
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: ReaderPageFrameKey.self,
                                            value: [page.id: geometry.frame(in: .named("reader.viewport"))]
                                        )
                                    }
                                }
                        }
                    }
                    if model.isAppending {
                        ProgressView("Loading next chapter…")
                            .tint(.white)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.vertical, 32)
                    } else if let error = model.appendError {
                        ReaderFailureView(message: error) { Task { await model.retryAppend() } }
                            .frame(height: 260)
                            .padding(.vertical, 24)
                    }
                }
            }
            .coordinateSpace(name: "reader.viewport")
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) { model.controlsVisible.toggle() }
            }
        }
    }

    private var readerBackground: Color {
        switch preferencesStore.preferences.readerBackground {
        case .paper: Color(red: 0.09, green: 0.075, blue: 0.055)
        case .black, .system: .black
        }
    }

    private func updateVisiblePage(_ frames: [ReaderPage.ID: CGRect], viewportHeight: CGFloat) {
        let viewport = CGRect(x: 0, y: 0, width: .greatestFiniteMagnitude, height: viewportHeight)
        guard let visible = frames.max(by: { lhs, rhs in
            lhs.value.intersection(viewport).height < rhs.value.intersection(viewport).height
        }), visible.value.intersection(viewport).height > 0,
              let page = model.loadedChapters.flatMap(\.pages).first(where: { $0.id == visible.key }) else { return }
        let anchor = visible.value.height > 0 ? min(max(-visible.value.minY / visible.value.height, 0), 1) : 0
        model.didDisplay(page, anchor: anchor)
    }

    private func scroll(_ request: ReaderScrollRequest, with proxy: ScrollViewProxy, animated: Bool = true) {
        let action = { proxy.scrollTo(request.page, anchor: UnitPoint(x: 0.5, y: request.anchor)) }
        if animated { withAnimation(.easeInOut(duration: 0.22), action) } else { action() }
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = preferencesStore.preferences.keepScreenAwake && scenePhase == .active
    }
}

private struct ReaderPageFrameKey: PreferenceKey {
    static let defaultValue: [ReaderPage.ID: CGRect] = [:]
    static func reduce(value: inout [ReaderPage.ID: CGRect], nextValue: () -> [ReaderPage.ID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
