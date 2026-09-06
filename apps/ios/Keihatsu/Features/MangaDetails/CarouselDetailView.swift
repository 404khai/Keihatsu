//
//  CarouselDetailView.swift
//  Keihatsu
//
//  Created by admin on 6/3/26.
//

import SwiftUI

struct CarouselDetailView: View {
    let item: ImageModel
    let animation: Namespace.ID
    @State private var showCategorySheet: Bool = false
    @State private var selectedCategories: Set<String> = ["DEFAULT"]
    @State private var showCollapsedHeader: Bool = false
    @State private var bookmarkedChapters: Set<Int> = []
    @State private var readChapters: Set<Int> = []
    @State private var navigateToChapter: ChapterEntry?
    
    private var chapters: [ChapterEntry] {
        if item.manga != nil { return [] }
        if item.title == "Ordeal" {
            return [
                ChapterEntry(id: 139, title: "Chapter 139", date: "14/5/26", resourcePrefix: "ordeal_ch139_"),
                ChapterEntry(id: 156, title: "Chapter 156", date: "15/5/26", resourcePrefix: "ordeal_ch156_"),
                ChapterEntry(id: 158, title: "Chapter 158", date: "16/5/26", resourcePrefix: "ordeal_ch158_")
            ]
        }

        return (1...10).map { index in
            ChapterEntry(id: index, title: "Chapter \(index)", date: "\(13 + index)/5/26", resourcePrefix: nil)
        }
    }

    private let categories = ["DEFAULT", "Thriller"]
    private var chapterListHeight: CGFloat {
        CGFloat(chapters.count) * 76
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                
                VStack(alignment: .leading, spacing: 24) {
                    overviewSection
                    chapterSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .coordinateSpace(name: "detailScroll")
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
//        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(showCollapsedHeader ? .visible : .hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onPreferenceChange(HeroHeaderVisibilityKey.self) { minY in
            showCollapsedHeader = minY < 50
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
//                    Image(item.image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 30, height: 30)
//                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showCollapsedHeader ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showCollapsedHeader)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Button {
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                
                Button {
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showCategorySheet) {
            categorySheet
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(item: $navigateToChapter) { chapter in
            ReaderView(item: item, chapters: chapters, initialChapterID: chapter.id)
        }
    }
    
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            heroImage
            
            VStack(alignment: .leading, spacing: 10) {
                Text(item.title.uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                HStack(spacing: 10){
                    Image(systemName: "person.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(item.manga.map { $0.author ?? "Author unavailable" } ?? "Brent Bristol, REDICE Studio")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                HStack(spacing: 10){
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(item.manga.map { $0.artist ?? "Artist unavailable" } ?? "Yong-Je Park")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                HStack(spacing: 10){
                    Image("manhuatop")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    Text((item.manga?.id.sourceID ?? "manhuatop").uppercased())
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
//                Text(item.category.uppercased())
//                    .font(.headline)
//                    .foregroundStyle(.white.opacity(0.9))
                
//                Text(item.metadataLine)
//                    .font(.subheadline)
//                    .foregroundStyle(.white.opacity(0.85))
                
                HStack(spacing: 14) {
                    Button {
                        showCategorySheet = true
                    } label: {
                        Label(item.manga == nil ? "Added to Library" : "Library coming soon", systemImage: "book.closed.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 28)
                            .frame(height: 52)
                            .background(.white, in: Capsule())
                    }
                    .disabled(item.manga != nil)
                    .glassEffect(.regular, in: .capsule)
                    
                    Button {
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
//                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .disabled(item.manga != nil)
                    .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: HeroHeaderVisibilityKey.self,
                        value: proxy.frame(in: .named("detailScroll")).minY
                    )
            }
        }
    }
    
    private var heroImage: some View {
        CatalogueCover(url: item.manga?.thumbnailURL, referer: item.manga?.url, asset: item.manga == nil ? item.image : nil)
            .frame(maxWidth: .infinity)
            .frame(height: 620)
            .overlay {
                LinearGradient(
                    colors: [
                        .black.opacity(0.02),
                        .black.opacity(0.12),
                        .black.opacity(0.5),
                        .black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .navigationTransition(.zoom(sourceID: item.id, in: animation))
            .modifier(BackgroundExtensionModifier())
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            
            Text(item.summary)
                .font(.body)
                .foregroundStyle(.white.opacity(0.82))
            
            Text(item.metadataLine)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var chapterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chapters")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            
            if item.manga != nil {
                Text("Chapter reading is coming soon.").foregroundStyle(.white.opacity(0.7))
                if let url = item.manga?.url, ["https", "http"].contains(url.scheme ?? "") {
                    Link("View on source", destination: url).buttonStyle(.bordered)
                }
            }
            List {
                ForEach(chapters) { chapter in
                    chapterRow(chapter)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(.white.opacity(0.08))
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .frame(height: chapterListHeight)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var categorySheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Select Categories")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 0) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            toggleCategory(category)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundStyle(selectedCategories.contains(category) ? Color.accentColor : .secondary)

                                Text(category)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)

                        if category != categories.last {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }

                Spacer(minLength: 16)

                Button {
                    showCategorySheet = false
                } label: {
                    Text("Add to Library")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    @ViewBuilder
    private func chapterRow(_ chapter: ChapterEntry) -> some View {
        let isBookmarked = bookmarkedChapters.contains(chapter.id)
        let isRead = readChapters.contains(chapter.id)

        Button {
            navigateToChapter = chapter
        } label: {
            HStack(spacing: 12) {
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.title)
                        .font(.headline)
                        .foregroundStyle(isRead ? .white.opacity(0.45) : .white)
//                        .strikethrough(isRead, color: .white.opacity(0.5))

                    Text(chapter.date)
                        .font(.subheadline)
                        .foregroundStyle(isRead ? .white.opacity(0.35) : .white.opacity(0.62))
                }

                Spacer()

                Image(systemName: "arrow.down.to.line.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleBookmark(for: chapter.id)
            } label: {
                Label(isBookmarked ? "Unbookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }
            .tint(.accentColor)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                toggleRead(for: chapter.id)
            } label: {
                Label(isRead ? "Mark Unread" : "Mark Read", systemImage: isRead ? "circle" : "checkmark.circle.fill")
            }
            .tint(isRead ? .gray : .green)
        }
    }

    private func toggleBookmark(for id: Int) {
        if bookmarkedChapters.contains(id) {
            bookmarkedChapters.remove(id)
        } else {
            bookmarkedChapters.insert(id)
        }
    }

    private func toggleRead(for id: Int) {
        if readChapters.contains(id) {
            readChapters.remove(id)
        } else {
            readChapters.insert(id)
        }
    }
}

struct ChapterEntry: Identifiable, Hashable {
    let id: Int
    let title: String
    let date: String
    let resourcePrefix: String?
}

private struct HeroHeaderVisibilityKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BackgroundExtensionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.backgroundExtensionEffect()
        } else {
            content
        }
    }
}

#Preview {
    @Previewable @Namespace var animation

    NavigationStack {
        CarouselDetailView(item: images[0], animation: animation)
    }
}
