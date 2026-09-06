//
//  ContentView.swift
//  Keihatsu
//
//  Created by admin on 5/27/26.
//

//
//  ContentView.swift
//  iOS26Test
//
//  Created by admin on 5/27/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @EnvironmentObject private var navigation: AppNavigation
    @Namespace private var animation
    @State private var expandMiniPlayer: Bool = false

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                NativeTabView()
                    .tabBarMinimizeBehavior(.onScrollDown)
//                    .tabViewBottomAccessory{
//                        MiniPlayerView()
//                            .matchedTransitionSource(id: "MINIPLAYER", in: animation)
//                            .onTapGesture {
//                                expandMiniPlayer.toggle()
//                            }
//                    }
            } else {
                NativeTabView()
            }
        }
        .fullScreenCover(isPresented: $expandMiniPlayer){
            ScrollView{

            }
            .safeAreaInset(edge: .top, spacing: 0){
                VStack(spacing: 10){
                    //Drag indicator mimic
                    Capsule()
                        .fill(.primary.secondary)
                        .frame(width: 35, height: 3)

                    HStack(spacing: 0){
                        PlayerInfo(.init(width: 80, height: 80))

                        Spacer(minLength: 0)

                        // Expanded Actions
                        Group {
                            Button("", systemImage: "star.circle.fill"){

                            }
                            Button("", systemImage: "ellipsis.circle.fill"){

                            }
                        }
                        .font(.title)
                        .foregroundStyle(Color.primary, Color.primary.opacity(0.1))
                    }
                    .padding(.horizontal, 15)
                }
                .navigationTransition(.zoom(sourceID: "MINIPLAYER", in: animation))
            }
            //To avoid transparency
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
        }
    }

    @ViewBuilder
    func NativeTabView() -> some View {
        TabView(selection: $navigation.selectedTab){
            // Tab.init("Home", systemImage: "house.fill", value: AppNavigation.Tab.home){
            //     HomeView(animation: animation)
            // }

            Tab.init("Library", systemImage: "books.vertical", value: AppNavigation.Tab.library){
                NavigationStack(path: $navigation.libraryPath) {
                    LibraryView(animation: animation)
                }
            }

            Tab.init("History", systemImage: "clock.arrow.circlepath", value: AppNavigation.Tab.history){
                NavigationStack(path: $navigation.historyPath) {
                    HistoryView()
                }
            }

            Tab.init("Plugins", systemImage: "puzzlepiece.extension", value: AppNavigation.Tab.extensions){
                NavigationStack(path: $navigation.extensionsPath) {
                    PluginsView()
                }
            }

            Tab.init("Profile", systemImage: "person.fill", value: AppNavigation.Tab.profile){
                NavigationStack(path: $navigation.profilePath) {
                    ProfileView()
                }
            }

            Tab.init("Search", systemImage: "magnifyingglass", value: AppNavigation.Tab.search, role: .search){
                NavigationStack(path: $navigation.searchPath) {
                    GlobalExtensionSearchView()
                }
            }


        }
        .tint(Color(hex: preferencesStore.preferences.theme.hex))
    }


    // Reusable Info
    @ViewBuilder
    func PlayerInfo(_ size : CGSize) -> some View{
        HStack(spacing: 12){
            Image(images.first?.image ?? "Image4")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: size.height / 4, style: .continuous))

            VStack(alignment: .leading, spacing: 6){
                Text("The Regressed Mercenary's Machinations")
                    .font(.callout)

                Text("Chapter 52")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .lineLimit(1)
        }
    }

    @ViewBuilder
    func MiniPlayerView() -> some View {
        HStack(spacing: 15) {
            PlayerInfo(.init(width: 30, height: 30))

            Spacer(minLength: 0)

            //Action Buttons
            Button {

            } label: {
                Image(systemName: "book.fill")
                    .contentShape(.rect)
            }
            .padding(.trailing, 10)

        }
        .padding(.horizontal, 15)
    }
}

#Preview {
    ContentView()
        .appEnvironment(.preview())
}
