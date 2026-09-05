//import SwiftUI
//
//struct RootScaffoldView: View {
//    @EnvironmentObject private var router: AppRouter
//    @Environment(\.keihatsuTheme) private var theme
//
//    var body: some View {
//        currentTabView
//        .background(theme.colors.background.ignoresSafeArea())
//        .safeAreaInset(edge: .bottom) {
//            bottomDock
//        }
//        .overlay(alignment: .bottomTrailing) {
//            searchShortcut
//                .padding(.trailing, theme.spacing.screenPadding)
//                .padding(.bottom, 86)
//        }
//    }
//
//    @ViewBuilder
//    private var currentTabView: some View {
//        switch router.selectedTab {
//        case .home:
//            HomeView()
//        case .library:
//            LibraryView()
//        case .history:
//            HistoryView()
//        case .extensions:
//            ExtensionsView()
//        case .profile:
//            ProfileView()
//        }
//    }
//
//    private var bottomDock: some View {
//        HStack(spacing: theme.spacing.sm) {
//            ForEach(PrimaryTab.allCases) { tab in
//                Button {
//                    withAnimation(theme.motion.navigationSpring) {
//                        router.selectTab(tab)
//                    }
//                } label: {
//                    tabButton(for: tab)
//                }
//                .buttonStyle(.plain)
//            }
//        }
//        .padding(.horizontal, theme.spacing.md)
//        .padding(.top, theme.spacing.sm)
//        .padding(.bottom, theme.spacing.md)
//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous))
//        .overlay {
//            RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous)
//                .stroke(theme.colors.border, lineWidth: 1)
//        }
//        .shadow(color: theme.elevation.card.color, radius: theme.elevation.card.radius, y: theme.elevation.card.y)
//        .padding(.horizontal, theme.spacing.screenPadding)
//        .padding(.top, theme.spacing.sm)
//        .background(Color.clear)
//    }
//
//    private var searchShortcut: some View {
//        Button {
//            withAnimation(theme.motion.emphasisSpring) {
//                router.open(.search)
//            }
//        } label: {
//            HStack(spacing: theme.spacing.sm) {
//                Image(systemName: "magnifyingglass")
//                    .font(.system(size: 16, weight: .semibold))
//                Text("Search")
//                    .font(theme.typography.caption.weight(.semibold))
//            }
//            .foregroundStyle(theme.colors.textPrimary)
//            .padding(.horizontal, theme.spacing.lg)
//            .padding(.vertical, theme.spacing.md)
//            .background(.ultraThinMaterial, in: Capsule())
//            .overlay {
//                Capsule()
//                    .stroke(theme.colors.border, lineWidth: 1)
//            }
//            .shadow(color: theme.elevation.card.color, radius: theme.elevation.card.radius, y: theme.elevation.card.y)
//        }
//        .buttonStyle(.plain)
//        .accessibilityLabel("Open search")
//    }
//
//    private func tabButton(for tab: PrimaryTab) -> some View {
//        let isSelected = router.selectedTab == tab
//
//        return VStack(spacing: theme.spacing.xs) {
//            Image(systemName: tab.symbolName)
//                .font(.system(size: 16, weight: .semibold))
//            Text(tab.rawValue)
//                .font(theme.typography.caption)
//                .lineLimit(1)
//        }
//        .frame(maxWidth: .infinity)
//        .foregroundStyle(isSelected ? theme.colors.textPrimary : theme.colors.textSecondary)
//        .padding(.vertical, theme.spacing.sm)
//        .background(
//            RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous)
//                .fill(isSelected ? theme.colors.surfaceElevated : .clear)
//        )
//    }
//}
