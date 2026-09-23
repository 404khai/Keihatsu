import SwiftUI
import Combine

import UIKit
import AVFoundation

struct ReaderView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var navigation: AppNavigation
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @StateObject private var model: ReaderViewModel
    @State private var showsComments = false
    @State private var showsReaderSettings = false
    @State private var zoomScale: CGFloat = 1
    @GestureState private var pinchMagnification: CGFloat = 1
    @StateObject private var volumeButtons = ReaderVolumeButtons()
    private let imagePipeline: ImagePipeline

    init(
        manga: Manga,
        chapters: [Chapter],
        context: ReaderLaunchContext,
        reader: any ReaderRepository,
        history: ReadingHistoryModel,
        imagePipeline: ImagePipeline,
        incognito: Bool,
        liveActivities: LiveActivityCoordinator? = nil
    ) {
        self.imagePipeline = imagePipeline
        _model = StateObject(wrappedValue: ReaderViewModel(
            manga: manga,
            chapters: chapters,
            context: context,
            reader: reader,
            history: history,
            imagePipeline: imagePipeline,
            incognito: incognito,
            liveActivities: liveActivities
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
                            page: model.displayedPage,
                            pageCount: model.currentPages.count,
                            isBookmarked: model.isBookmarked,
                            canOpenOlder: model.hasOlderChapter,
                            canOpenNewer: model.hasNewerChapter,
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
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.manga.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(model.currentChapter?.name ?? "Chapter")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsReaderSettings = true } label: {
                    Image(systemName: "gearshape").foregroundStyle(.white)
                }
                .accessibilityLabel("Reader settings")
            }

        }
        .toolbar(model.controlsVisible ? .visible : .hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!model.controlsVisible)
        .persistentSystemOverlays(model.controlsVisible ? .automatic : .hidden)
        .sheet(isPresented: $showsComments) {
            ReaderCommentsSheet(manga: model.manga, chapter: model.currentChapter)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsReaderSettings) {
            ReaderOptionsSheet()
                .environmentObject(preferencesStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.thickMaterial)
        }
        .onAppear {
            navigation.readerDidAppear(chapter: model.currentChapter?.id ?? model.context.chapter)
            updateIdleTimer()
            updateVolumeButtons()
        }
        .onDisappear {
            navigation.readerDidDisappear()
            UIApplication.shared.isIdleTimerDisabled = false
            volumeButtons.stop()
            Task { await model.end() }
        }
        .onChange(of: model.currentChapter?.id) { _, chapter in
            guard let chapter else { return }
            navigation.readerDidAppear(chapter: chapter)
        }
        .onChange(of: preferencesStore.preferences.keepScreenAwake) { updateIdleTimer() }
        .onChange(of: preferencesStore.preferences.readerDirection) { _, _ in zoomScale = 1 }
        .onChange(of: preferencesStore.preferences.volumeButtonsEnabled) { updateVolumeButtons() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.resume()
                updateIdleTimer()
                updateVolumeButtons()
            case .inactive, .background:
                UIApplication.shared.isIdleTimerDisabled = false
                volumeButtons.stop()
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
            if preferencesStore.preferences.readerDirection == .vertical {
            ScrollView([.vertical, .horizontal]) {
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
                .frame(width: viewport.size.width * effectiveZoom)
            }
            .coordinateSpace(name: "reader.viewport")
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .simultaneousGesture(zoomGesture)
            .highPriorityGesture(TapGesture(count: 2).onEnded { toggleZoom() })
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) { model.controlsVisible.toggle() }
            }
            } else {
                let pages = model.currentPages
                let rtl = preferencesStore.preferences.readerDirection == .rightToLeft
                let displayedPages = rtl ? Array(pages.reversed()) : pages
                TabView(selection: Binding(
                    get: { rtl ? max(pages.count - 1 - model.currentPageIndex, 0) : model.currentPageIndex },
                    set: { model.scrub(to: rtl ? pages.count - 1 - $0 : $0) }
                )) {
                    ForEach(Array(displayedPages.enumerated()), id: \.element.id) { index, page in
                        ReaderPageView(page: page, pipeline: imagePipeline)
                            .scaleEffect(effectiveZoom)
                            .simultaneousGesture(zoomGesture)
                            .highPriorityGesture(TapGesture(count: 2).onEnded { toggleZoom() })
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private var effectiveZoom: CGFloat {
        min(max(zoomScale * (preferencesStore.preferences.pinchToZoom ? pinchMagnification : 1), 1), 4)
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .updating($pinchMagnification) { value, state, _ in
                if preferencesStore.preferences.pinchToZoom { state = value.magnification }
            }
            .onEnded { value in
                guard preferencesStore.preferences.pinchToZoom else { return }
                zoomScale = min(max(zoomScale * value.magnification, 1), 4)
            }
    }

    private func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = zoomScale > 1 ? 1 : 2
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

    private func updateVolumeButtons() {
        guard preferencesStore.preferences.volumeButtonsEnabled, scenePhase == .active else {
            volumeButtons.stop()
            return
        }
        volumeButtons.start { direction in
            let step = preferencesStore.preferences.readerDirection == .rightToLeft ? -direction : direction
            model.scrub(to: model.currentPageIndex + step)
        }
    }
}

@MainActor
private final class ReaderVolumeButtons: ObservableObject {
    private var observation: NSKeyValueObservation?
    private var previousVolume: Float = 0

    func start(onPress: @escaping (Int) -> Void) {
        stop()
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        previousVolume = session.outputVolume
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let volume = change.newValue else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                let direction = volume > self.previousVolume ? 1 : -1
                guard volume != self.previousVolume else { return }
                self.previousVolume = volume
                onPress(direction)
            }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
    }
}

private struct ReaderPageFrameKey: PreferenceKey {
    static let defaultValue: [ReaderPage.ID: CGRect] = [:]
    static func reduce(value: inout [ReaderPage.ID: CGRect], nextValue: () -> [ReaderPage.ID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}


private struct ReaderOptionsSheet: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Read mode") {
                    Picker("Read mode", selection: $preferencesStore.preferences.readerDirection) {
                        Text("Default").tag(ReaderDirectionPreference.vertical)
                        Text("Horizontal (RTL)").tag(ReaderDirectionPreference.rightToLeft)
                        Text("Horizontal (LTR)").tag(ReaderDirectionPreference.leftToRight)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Section {
                    Toggle("Pinch to zoom", isOn: $preferencesStore.preferences.pinchToZoom)
                    Toggle("Enable volume buttons", isOn: $preferencesStore.preferences.volumeButtonsEnabled)
                } footer: {
                    Text("Use volume buttons for switching pages")
                }
            }
            .navigationTitle("Reader settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
