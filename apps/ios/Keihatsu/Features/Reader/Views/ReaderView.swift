//
//  ReaderView.swift
//  Keihatsu
//
//  Created by admin on 6/3/26.
//

import SwiftUI
import UIKit

struct ReaderView: View {
    let item: ImageModel
    let chapters: [ChapterEntry]
    let initialChapterID: Int

    @State private var currentChapterIndex: Int = 0
    @State private var currentPageIndex: Int = 0
    @State private var pageURLs: [URL] = []
    @State private var bookmarked: Bool = false
    @State private var showComments: Bool = false

    init(item: ImageModel, chapters: [ChapterEntry], initialChapterID: Int) {
        self.item = item
        self.chapters = chapters
        self.initialChapterID = initialChapterID
        _currentChapterIndex = State(initialValue: chapters.firstIndex(where: { $0.id == initialChapterID }) ?? 0)
    }

    private var currentChapter: ChapterEntry {
        chapters[currentChapterIndex]
    }

    private var sliderUpperBound: Double {
        Double(max(pageURLs.count - 1, 1))
    }

    private var clampedPageIndex: Int {
        min(currentPageIndex, max(pageURLs.count - 1, 0))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                if pageURLs.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(pageURLs.enumerated()), id: \.offset) { index, pageURL in
                                ReaderPageImage(url: pageURL)
                                    .id(index)
                                    .background {
                                        GeometryReader { geometry in
                                            Color.clear
                                                .preference(
                                                    key: ReaderPageOffsetKey.self,
                                                    value: [index: abs(geometry.frame(in: .named("readerScroll")).minY)]
                                                )
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .coordinateSpace(name: "readerScroll")
//                    .scrollEdgeEffectStyle(.soft, for: .top)
                    .scrollIndicators(.visible)
                    .onPreferenceChange(ReaderPageOffsetKey.self) { offsets in
                        guard let visibleIndex = offsets.min(by: { $0.value < $1.value })?.key else {
                            return
                        }

                        if visibleIndex != currentPageIndex {
                            currentPageIndex = visibleIndex
                        }
                    }
                }

                VStack(spacing: 14) {
                    floatingAction(systemName: bookmarked ? "bookmark.fill" : "bookmark") {
                        bookmarked.toggle()
                    }

                    floatingAction(systemName: "text.bubble") {
                        showComments = true
                    }
                }
                .padding(.top, 500)
                .padding(.trailing, 16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                readerControls(proxy: proxy)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(currentChapter.title)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                
            }
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                loadPages()
            }
            .onChange(of: currentChapterIndex) {
                currentPageIndex = 0
                loadPages()

                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(0, anchor: .top)
                }
            }
            .sheet(isPresented: $showComments) {
                ReaderCommentsSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
//                    .presentationBackground(.regularMaterial)
            }
        }
    }

    private func readerControls(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    if currentChapterIndex > 0 {
                        currentChapterIndex -= 1
                    }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title2)
                        .frame(width: 54, height: 54)
//                        .background(.ultraThinMaterial, in: Circle())
                }
                .disabled(currentChapterIndex == 0)
                .glassEffect(.regular.interactive(), in: .circle)

                HStack(spacing: 12) {
                    Text("\(max(currentPageIndex + 1, 1))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 24)
                    
                    
                    Slider(
                        value: Binding(
                            get: { Double(clampedPageIndex) },
                            set: { value in
                                let targetIndex = min(Int(value.rounded()), max(pageURLs.count - 1, 0))
                                currentPageIndex = targetIndex

                                withAnimation(.easeInOut(duration: 0.2)) {
                                    proxy.scrollTo(targetIndex, anchor: .top)
                                }
                            }
                        ),
                        in: 0...sliderUpperBound,
                        step: 1
                    )
                    .tint(.green)
                    .disabled(pageURLs.count <= 1)
                
//                    UISlider.appearance().tintColor = .green
//                    UISlider(){
//
//                    }
//                    .trackConfiguration = .init(allowsTickValuesOnly: true, numberOfTicks: 5)
                    

                    Text("\(max(pageURLs.count, 1))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 24)
                }
                .padding(.horizontal, 14)
                .frame(height: 54)
//                .background(.ultraThinMaterial, in: Capsule())
                .glassEffect(.regular.interactive(), in: .capsule)

                Button {
                    if currentChapterIndex < chapters.count - 1 {
                        currentChapterIndex += 1
                    }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title2)
                        .frame(width: 54, height: 54)
//                        .background(.ultraThinMaterial, in: Circle())
                }
                .disabled(currentChapterIndex >= chapters.count - 1)
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
//        .background(.black.opacity(0.88))
    }

    private func floatingAction(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
//                .background(.glassEffect)
//                .background(.black.opacity(0.82), in: Circle())
        }
        .glassEffect(.regular.interactive(), in: .circle)
    }

    private func loadPages() {
        guard let prefix = currentChapter.resourcePrefix,
              let resourceURL = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil)
        else {
            pageURLs = []
            return
        }

        pageURLs = enumerator
            .compactMap { $0 as? URL }
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .filter { ["jpg", "jpeg", "png", "webp"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        currentPageIndex = min(currentPageIndex, max(pageURLs.count - 1, 0))
    }
}

private struct ReaderCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var commentText: String = ""

    private let comments: [ReaderComment] = [
        ReaderComment(
            author: "kingkhai.dev",
            body: "dope asf",
            timeAgo: "19 minutes ago",
            replyCountText: "Hide replies",
            imageName: "Image4",
            replies: ["cool fr"]
        ),
        ReaderComment(
            author: "kingkhai.dev",
            body: "goof",
            timeAgo: "19 minutes ago",
            replyCountText: "View 1 replies",
            imageName: nil,
            replies: []
        ),
        ReaderComment(
            author: "mercenary.reader",
            body: "This chapter pacing is wild.",
            timeAgo: "34 minutes ago",
            replyCountText: "Reply",
            imageName: nil,
            replies: []
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                
                ZStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
//                                .background(.regularMaterial, in: Circle())
                        }
                        .glassEffect(.regular.interactive(), in: .circle)

                        Spacer()

                        Button {
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
//                                .background(.regularMaterial, in: Circle())
                        }
                        .glassEffect(.regular.interactive(), in: .circle)
                    }

                    Text("Comments (7)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(spacing: 28) {
                        ForEach(comments) { comment in
                            ReaderCommentRow(comment: comment)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.visible)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: 12) {

                    // Avatar (no background)
                    Image("Image4")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())

                    // Input Area
                    HStack {
                        TextField("Add comments...", text: $commentText)
                            .textFieldStyle(.plain)

                        Button {

                        } label: {
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(.regularMaterial)
            }
        }
    }
}

private struct ReaderCommentRow: View {
    let comment: ReaderComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Image1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 10) {
                Text(comment.author)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(comment.body)
                    .font(.title3)
                    .foregroundStyle(.primary)

                if let imageName = comment.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                HStack(spacing: 20) {
                    Text(comment.timeAgo)
                        .foregroundStyle(.secondary)

                    Text("Reply")
                        .foregroundStyle(.primary.opacity(0.85))
                }
                .font(.subheadline)

                if !comment.replyCountText.isEmpty {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(.secondary.opacity(0.35))
                            .frame(width: 32, height: 1)

                        Text(comment.replyCountText)
                            .font(.headline)
                            .foregroundStyle(.primary.opacity(0.78))

                        Image(systemName: comment.replyCountText.contains("View") ? "chevron.down" : "chevron.up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(comment.replies, id: \.self) { reply in
                    HStack(alignment: .top, spacing: 12) {
                        Image("Image1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 8) {
                            Text(comment.author)
                                .font(.headline)
                                .foregroundStyle(.primary.opacity(0.88))

                            Text(reply)
                                .font(.title3)
                                .foregroundStyle(.primary)

                            HStack(spacing: 20) {
                                Text(comment.timeAgo)
                                    .foregroundStyle(.secondary)

                                Text("Reply")
                                    .foregroundStyle(.primary.opacity(0.85))
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.top, 6)
                }
            }

            Spacer(minLength: 0)

            Button {
            } label: {
                Image(systemName: "heart")
                    .font(.title3)
                    .foregroundStyle(.primary.opacity(0.78))
            }
            .padding(.top, 4)
        }
    }
}

private struct ReaderComment: Identifiable {
    let id = UUID()
    let author: String
    let body: String
    let timeAgo: String
    let replyCountText: String
    let imageName: String?
    let replies: [String]
}

private struct ReaderPageImage: View {
    let url: URL

    var body: some View {
        if let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color.black)
        } else {
            Color.black
                .frame(maxWidth: .infinity, minHeight: 300)
        }
    }
}

private struct ReaderPageOffsetKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#Preview {
    NavigationStack {
        ReaderView(
            item: images[4],
            chapters: [
                ChapterEntry(id: 139, title: "Chapter 139", date: "14/5/26", resourcePrefix: "ordeal_ch139_"),
                ChapterEntry(id: 156, title: "Chapter 156", date: "15/5/26", resourcePrefix: "ordeal_ch156_"),
                ChapterEntry(id: 158, title: "Chapter 158", date: "16/5/26", resourcePrefix: "ordeal_ch158_")
            ],
            initialChapterID: 139
        )
    }
}
