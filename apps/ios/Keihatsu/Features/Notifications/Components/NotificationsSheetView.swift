import SwiftUI

struct NotificationsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @State private var selectedTab: NotificationTab = .all
    @State private var notifications: [KeihatsuNotification] = KeihatsuNotification.samples
    @State private var selectionMode = false
    @State private var selectedIDs: Set<UUID> = []

    private var accent: Color {
        Color(hex: preferencesStore.preferences.theme.hex)
    }

    private var filteredNotifications: [KeihatsuNotification] {
        notifications.filter { notification in
            selectedTab == .all || notification.tab == selectedTab
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Notifications", selection: $selectedTab) {
                    ForEach(NotificationTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)

                List {
                    ForEach(filteredNotifications) { notification in
                        NotificationRow(
                            notification: notification,
                            isSelected: selectedIDs.contains(notification.id),
                            selectionMode: selectionMode,
                            accent: accent
                        ) {
                            toggleSelection(for: notification.id)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            if selectionMode {
                                toggleSelection(for: notification.id)
                            } else {
                                markRead(notification.id)
                            }
                        }
                        .onLongPressGesture {
                            selectionMode = true
                            selectedIDs = [notification.id]
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteNotifications(Set([notification.id]))
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                markRead(notification.id)
                            } label: {
                                Label(notification.isRead ? "Mark Unread" : "Mark Read", systemImage: notification.isRead ? "circle" : "checkmark.circle.fill")
                            }
                            .tint(notification.isRead ? .gray : accent)
                        }
                    }
                    // .tint(.primary)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .overlay {
                    if filteredNotifications.isEmpty {
                        ContentUnavailableView(
                            "You're All Caught Up",
                            systemImage: "bell.badge.slash",
                            description: Text("No notifications to show right now.")
                        )
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if selectionMode {
                            selectionMode = false
                            selectedIDs.removeAll()
                        } else {
                            dismiss()
                        }
                    } label: {
                        if selectionMode {
                            Text("Done")
                        } else {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if selectionMode {
                        Button(role: .destructive) {
                            deleteNotifications(selectedIDs)
                        } label: {
                            Image(systemName: "trash.fill")
                        }
                        .disabled(selectedIDs.isEmpty)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func markRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead.toggle()
    }

    private func toggleSelection(for id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func deleteNotifications(_ ids: Set<UUID>) {
        notifications.removeAll { ids.contains($0.id) }
        selectedIDs.subtract(ids)
        if selectedIDs.isEmpty {
            selectionMode = false
        }
    }
}

private struct NotificationRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let notification: KeihatsuNotification
    let isSelected: Bool
    let selectionMode: Bool
    let accent: Color
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if selectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? accent : .secondary)
                }
                .buttonStyle(.plain)
            }

            leadingVisual

            notificationContent

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? accent.opacity(0.12) : Color(.secondarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? accent.opacity(0.38) : Color(.separator).opacity(0.25), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var leadingVisual: some View {
        if let imageName = notification.imageName {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 54, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image(systemName: notification.icon)
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(systemIconForeground)
                .frame(width: 44, height: 44)
                .background(systemIconBackground, in: Circle())
                .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    private var notificationContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(notification.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !notification.isRead {
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                }
            }

            Text(notification.displayMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(notification.time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var systemIconForeground: Color {
        colorScheme == .dark ? notification.systemColor : (notification.usesDarkSystemSymbol ? .black : .white)
    }

    private var systemIconBackground: Color {
        colorScheme == .dark ? .black : notification.systemColor
    }
}

private enum NotificationTab: String, CaseIterable, Identifiable {
    case all
    case updates
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .updates: return "Updates"
        case .system: return "System"
        }
    }
}

private struct KeihatsuNotification: Identifiable {
    let id = UUID()
    let tab: NotificationTab
    let icon: String
    let title: String
    let message: String
    let time: String
    var imageName: String?
    var mangaTitle: String?
    var chapters: [String] = []
    var systemColor: Color = Color(hex: "42D9F5")
    var usesDarkSystemSymbol = false
    var isRead: Bool

    var displayTitle: String {
        guard !chapters.isEmpty else { return title }
        return mangaTitle ?? "Manwha Name Not Available"
        // return chapters.count == 1 ? "New Chapter" : "New Chapters"
    }

    var displayMessage: String {
        guard !chapters.isEmpty else { return message }
        let chapterLabel = chapters.count == 1 ? "chapter" : "chapters"
        return "\(chapters.count) \(chapterLabel) • \(chapters.joined(separator: ", "))\(chapters.count > 2 ? "..." : "")"
    }

    static let samples: [KeihatsuNotification] = [
        KeihatsuNotification(tab: .updates, icon: "book.closed.fill", title: "Ordeal", message: "", time: "2m ago", imageName: "Image5", mangaTitle: "Ordeal", chapters: ["Chapter 132", "145", "155"], isRead: false),
        KeihatsuNotification(tab: .updates, icon: "book.closed.fill", title: "Latna Saga", message: "", time: "18m ago", imageName: "Image2", mangaTitle: "Latna Saga", chapters: ["Chapter 88"], isRead: false),
        KeihatsuNotification(tab: .updates, icon: "book.closed.fill", title: "The World After the Fall", message: "", time: "Yesterday", imageName: "Image3", mangaTitle: "The World After the Fall", chapters: ["Chapter 71", "72", "73"], isRead: true),
        KeihatsuNotification(tab: .system, icon: "arrow.down.to.line.compact", title: "Update Available", message: "A new Keihatsu build is ready with reader and plugin improvements.", time: "1h ago", systemColor: Color(hex: "8DE328"), usesDarkSystemSymbol: true, isRead: true),
        KeihatsuNotification(tab: .system, icon: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill", title: "Sync Queued", message: "Reading history will sync when your account session refreshes.", time: "2h ago", systemColor: Color(hex: "42D9F5"), usesDarkSystemSymbol: true, isRead: true),
        KeihatsuNotification(tab: .system, icon: "puzzlepiece.extension.fill", title: "Source Warning", message: "MangaFire is responding slowly. Try again later if pages fail.", time: "3h ago", systemColor: Color(hex: "FF7A3D"), isRead: false)
    ]
}

#Preview {
    NotificationsSheetView()
        .environmentObject(AppPreferencesStore(userDefaults: .standard))
}
