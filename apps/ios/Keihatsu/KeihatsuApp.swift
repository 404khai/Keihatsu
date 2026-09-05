//
//  KeihatsuApp.swift
//  Keihatsu
//
//  Created by admin on 5/27/26.
//

//import SwiftUI
//
//@main
//struct KeihatsuApp: App {
//    @StateObject private var appEnvironment = AppEnvironment()
//    @StateObject private var appRouter = AppRouter()
//
//    var body: some Scene {
//        WindowGroup {
//            AppRootView()
//                .environmentObject(appEnvironment)
//                .environmentObject(appRouter)
//                .environment(\.keihatsuTheme, appEnvironment.theme)
//        }
//    }
//}

import SwiftUI

@main
struct KeihatsuApp: App {
    @StateObject private var preferencesStore = AppPreferencesStore()
    @StateObject private var syncQueueStore = SyncQueueStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferencesStore)
                .environmentObject(syncQueueStore)
                .environment(\.keihatsuTheme, KeihatsuTheme.default)
                .preferredColorScheme(preferredColorScheme)
                .tint(Color(hex: preferencesStore.preferences.theme.hex))
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch preferencesStore.preferences.colorScheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
