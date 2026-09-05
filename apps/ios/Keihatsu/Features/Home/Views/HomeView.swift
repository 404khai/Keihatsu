//
//  ContentView.swift
//  iOS26Test
//
//  Created by admin on 5/27/26.
//

import SwiftUI

struct HomeView: View {
    let animation: Namespace.ID
    @State private var showMenu: Bool = false
    @State private var showNotifications: Bool = false
    @State private var activeID: UUID?
    @State private var selectedType: CarouselType = .type3

    private var updateSections: [UpdateSection] {
        [
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 36){
                    let s = selectedType.settings
                    
                    CustomCarousel(config: .init(hasOpacity: s.hasOpacity, hasScale: s.hasScale, cardWidth: s.cardWidth, minCardWidth: s.minCardWidth), selection: $activeID, data: images) { item in
                        NavigationLink(value: item) {
                            Image(item.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
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

                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Updates")
                                .font(.title3.weight(.semibold))
                            
                            Spacer()
                            
                            Button {
                                
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

                                VStack(spacing: 12) {
                                    ForEach(section.items) { entry in
                                        NavigationLink(value: entry.item) {
                                            HStack(spacing: 12) {
                                                Image(entry.item.image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
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
                AccountSheetView()
                    .navigationTransition(.zoom(sourceID: "Account", in: animation))
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSheetView()
                    .navigationTransition(.zoom(sourceID: "Notifications", in: animation))
            }
            .navigationDestination(for: ImageModel.self) { item in
                CarouselDetailView(item: item, animation: animation)
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
}


