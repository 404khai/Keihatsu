//
//  ContentView.swift
//  iOS26Test
//
//  Created by admin on 5/27/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var sources: SourcePreferencesStore
    @EnvironmentObject private var model: HomeViewModel
    @EnvironmentObject private var readingHistory: ReadingHistoryModel
    @EnvironmentObject private var navigation: AppNavigation
    let animation: Namespace.ID
    @State private var showMenu: Bool = false
    @State private var showNotifications: Bool = false
    @State private var activeID: UUID?
    @State private var selectedType: CarouselType = .type3

    private var items: [ImageModel] { environment.services.isPreview ? images : model.mangas.map(ImageModel.init(manga:)) }

    private var continueReading: [ReaderProgressRecord] {
        var seen = Set<MangaIdentity>()
        return readingHistory.entries.filter { seen.insert($0.manga.id).inserted }.prefix(6).map { $0 }
    }

    private var updateSections: [UpdateSection] {
        if !environment.services.isPreview {
            return model.sections.map { section in
                UpdateSection(title: section.source.name, items: section.mangas.map { manga in
                    UpdateEntry(item: ImageModel(manga: manga), chapterLine: manga.genres.joined(separator: " • "), trailingIcon: "chevron.right")
                })
            }
        }
        return [
            UpdateSection(
                title: "Today",
                items: [
                    UpdateEntry(item: images[4], chapterLine: "Chapter 132, 135...", trailingIcon: "arrow.down.to.line.circle"),
                    UpdateEntry(item: images[10], chapterLine: "Chapter 110, 111...", trailingIcon: "arrow.down.to.line.circle"),
                    UpdateEntry(item: images[9], chapterLine: "Chapter 57, 58...", trailingIcon: "arrow.down.to.line.circle")
                ]
            ),
            UpdateSection(
                title: "Tomorrow",
                items: [
                    UpdateEntry(item: images[11], chapterLine: "Chapter 85, 86...", trailingIcon: "calendar.badge.clock"),
                    UpdateEntry(item: images[8], chapterLine: "Chapter 92, 93...", trailingIcon: "calendar.badge.clock")
                ]
            )
        ]
    }

    var body: some View {
        NavigationStack(path: $navigation.homePath) {
            ScrollView {
                LazyVStack(spacing: 36){
                    if sources.isLoading || model.isLoading { ProgressView("Loading latest titles…") }
                    if let error = sources.error {
                        CatalogueMessage(message: error) { Task { await sources.load(force: true) } }
                    }
                    ForEach(model.sections.filter { $0.error != nil }) { section in
                        CatalogueMessage(message: "\(section.source.name): \(section.error ?? "")" + (section.isCached ? " Showing saved titles." : "")) {
                            Task { await model.load(sources: sources.enabledSources) }
                        }
                    }
                    if sources.enabledSources.isEmpty && !sources.isLoading && sources.error == nil && !environment.services.isPreview {
                        ContentUnavailableView {
                            Label("No enabled sources", systemImage: "puzzlepiece.extension")
                        } description: { Text("Enable an available source to discover titles.") }
                        actions: { Button("Manage Sources") { navigation.selectedTab = .extensions } }
                    }
                    let s = selectedType.settings

                    if !continueReading.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Continue Reading").font(.title3.weight(.semibold))
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 14) {
                                    ForEach(continueReading) { entry in
                                        NavigationLink(value: MangaDetailsSeed(manga: entry.manga, fallbackChapters: [entry.chapter])) {
                                            HStack(spacing: 12) {
                                                CatalogueCover(url: entry.manga.thumbnailURL, referer: entry.manga.url)
                                                    .frame(width: 58, height: 82)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(entry.manga.title).font(.headline).lineLimit(2)
                                                    Text("\(entry.chapter.name) • Page \(entry.displayedPage) of \(max(entry.totalPages, 1))")
                                                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                                }
                                                .frame(width: 180, alignment: .leading)
                                            }
                                            .padding(10)
                                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                    if !items.isEmpty {
                    CustomCarousel(config: .init(hasOpacity: s.hasOpacity, hasScale: s.hasScale, cardWidth: s.cardWidth, minCardWidth: s.minCardWidth), selection: $activeID, data: items) { item in
                        NavigationLink(value: MangaDetailsSeed(item: item)) {
                            CatalogueCover(url: item.manga?.thumbnailURL, referer: item.manga?.url, asset: item.manga == nil ? item.image : nil)
                                .overlay(alignment: .bottomLeading) {
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .overlay(alignment: .bottomLeading) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                                .lineLimit(2)
                                            
                                            Text(item.metadataLine)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.85))
                                                .lineLimit(1)
                                        }
                                        .padding(16)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: item.id, in: animation)
                    }
                    .frame(height: 250)
                    }

                    if !model.isLoading && !sources.isLoading && items.isEmpty && !sources.enabledSources.isEmpty && model.sections.allSatisfy({ $0.error == nil }) {
                        CatalogueMessage(message: "No latest titles found. Pull to refresh.")
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text(environment.services.isPreview ? "Updates" : "Latest")
                                .font(.title3.weight(.semibold))
                            
                            Spacer()
                            
                            Button {
                                navigation.selectedTab = .search
                            } label: {
                                Text("See More")
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        ForEach(updateSections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                LazyVStack(spacing: 12) {
                                    ForEach(section.items) { entry in
                                        NavigationLink(value: MangaDetailsSeed(item: entry.item)) {
                                            HStack(spacing: 12) {
                                                CatalogueCover(url: entry.item.manga?.thumbnailURL, referer: entry.item.manga?.url, asset: entry.item.manga == nil ? entry.item.image : nil)
                                                    .frame(width: 54, height: 72)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(entry.item.title)
                                                        .font(.headline)
                                                        .foregroundStyle(.primary)
                                                        .lineLimit(1)

                                                    Text(entry.chapterLine)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }

                                                Spacer(minLength: 0)

                                                Image(systemName: entry.trailingIcon)
                                                    .font(.title3.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .task { await sources.load() }
            .task { await readingHistory.refresh() }
            .task(id: sources.revision) { await model.load(sources: sources.enabledSources) }
            .refreshable { await model.load(sources: sources.enabledSources) }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Notifications", systemImage: "bell.fill") {
                        showNotifications.toggle()
                    }
                    .matchedTransitionSource(id: "Notifications", in: animation)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Account", systemImage: "person.fill") {
                        showMenu.toggle()
                    }
                }
                .matchedTransitionSource(id: "Account", in: animation)
            }
            .sheet(isPresented: $showMenu) {
                NavigationStack {
                    ProfileView()
                }
                .navigationTransition(.zoom(sourceID: "Account", in: animation))
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSheetView()
                    .navigationTransition(.zoom(sourceID: "Notifications", in: animation))
            }
            .navigationDestination(for: MangaDetailsSeed.self) { seed in
                CarouselDetailView(seed: seed, animation: animation, origin: .home)
            }
        }
    }

    private enum CarouselType: CaseIterable, Hashable {
        case type1, type2, type3, type4
        
        var title: String {
            switch self{
            case .type1: return "Basic"
            case .type2: return "Fade"
            case .type3: return "Zoom"
            case .type4: return "Cinematic"
            }
        }
        
        var settings: (hasOpacity: Bool, hasScale: Bool, cardWidth: CGFloat, minCardWidth: CGFloat){
            switch self{
            case .type1: return (false, false, 200,30)
            case .type2: return (true, false, 200,30)
            case .type3: return (false, true, 200,30)
            case .type4: return (true, true, 200,30)
            }
        }
    }

    private struct UpdateSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [UpdateEntry]
    }

    private struct UpdateEntry: Identifiable {
        let id = UUID()
        let item: ImageModel
        let chapterLine: String
        let trailingIcon: String
    }
}

#Preview {
    @Previewable @Namespace var animation
    HomeView(animation: animation)
        .appEnvironment(.preview())
}
