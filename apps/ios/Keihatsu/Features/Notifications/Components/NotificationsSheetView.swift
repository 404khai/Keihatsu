import SwiftUI
import Combine

@MainActor
final class InboxViewModel: ObservableObject {
    @Published var items: [InboxNotificationDTO] = []
    @Published var unreadCount = 0 {
        didSet { unreadStore?.setCount(unreadCount) }
    }
    @Published var loading = false
    @Published var error: String?
    @Published var category = "All"
    private var cursor: String?
    private var api: NotificationsAPI?
    private var token: String?
    private var unreadStore: NotificationUnreadStore?

    func configure(api: NotificationsAPI, token: String?, unreadStore: NotificationUnreadStore? = nil) {
        self.api = api
        self.token = token
        self.unreadStore = unreadStore
        unreadCount = unreadStore?.count ?? 0
    }

    func refresh() async {
        guard let api, let token else { error = "Sign in to see your Inbox."; return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            let page = try await api.list(token: token, category: category == "All" ? nil : category.uppercased())
            items = page.items
            cursor = page.nextCursor
            unreadCount = try await api.unreadCount(token: token)
        } catch { self.error = "Could not load Inbox. Check your connection and retry." }
    }

    func loadMore() async {
        guard let api, let token, let cursor, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let page = try await api.list(token: token, cursor: cursor, category: category == "All" ? nil : category.uppercased())
            items += page.items
            self.cursor = page.nextCursor
        } catch { self.error = "Could not load more notifications." }
    }

    func markRead(_ item: InboxNotificationDTO) async {
        guard let api, let token, !item.isRead,
              let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].readAt = ISO8601DateFormatter().string(from: .now)
        unreadCount = max(0, unreadCount - 1)
        do { try await api.markRead(item.id, token: token) }
        catch { items[index] = item; unreadCount += 1; self.error = "Could not mark notification as read." }
    }

    func delete(_ item: InboxNotificationDTO) async {
        guard let api, let token, let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items.remove(at: index)
        if !item.isRead { unreadCount = max(0, unreadCount - 1) }
        do { try await api.delete(item.id, token: token) }
        catch { items.insert(item, at: index); if !item.isRead { unreadCount += 1 }; self.error = "Could not delete notification." }
    }

    func readAll() async {
        guard let api, let token else { return }
        let previous = items, previousCount = unreadCount
        let timestamp = ISO8601DateFormatter().string(from: .now)
        for index in items.indices { items[index].readAt = timestamp }
        unreadCount = 0
        do { try await api.readAll(token: token) }
        catch { items = previous; unreadCount = previousCount; self.error = "Could not mark all as read." }
    }

    var hasMore: Bool { cursor != nil }
}

struct NotificationsSheetView: View {
    var title = "Notifications"
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = InboxViewModel()
    @State private var showsPreferences = false
    private let categories = ["All", "Updates", "Comments", "System", "Account"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category", selection: $model.category) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: model.category) { _, _ in Task { await model.refresh() } }

                if model.loading && model.items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = model.error, model.items.isEmpty {
                    ContentUnavailableView(error, systemImage: "wifi.slash")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Button("Retry") { Task { await model.refresh() } }.padding()
                } else if model.items.isEmpty {
                    ContentUnavailableView("You're All Caught Up", systemImage: "bell.badge.slash")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(model.items) { item in
                            Button {
                                Task {
                                    await model.markRead(item)
                                    guard let url = URL(string: item.deepLink) else { return }
                                    _ = environment.navigation.handleNotificationURL(url)
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.type == "CHAPTER_UPDATE" ? "book.closed.fill" :
                                        item.type.hasPrefix("COMMENT_") ? "bubble.left.fill" : "bell.fill")
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.title).font(.headline)
                                            if !item.isRead { Circle().fill(.tint).frame(width: 7, height: 7) }
                                        }
                                        Text(item.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                        Text(item.date, style: .relative).font(.caption).foregroundStyle(.tertiary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(item.title). \(item.body). \(item.isRead ? "Read" : "Unread")")
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { Task { await model.delete(item) } }
                                if !item.isRead {
                                    Button("Read", systemImage: "checkmark") { Task { await model.markRead(item) } }
                                }
                            }
                        }
                        if model.hasMore {
                            ProgressView().frame(maxWidth: .infinity)
                                .task { await model.loadMore() }
                        }
                    }
                    .refreshable { await model.refresh() }
                }
            }
            .navigationTitle("\(title)\(model.unreadCount > 0 ? " (\(model.unreadCount))" : "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Read all") { Task { await model.readAll() } }.disabled(model.unreadCount == 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Preferences", systemImage: "slider.horizontal.3") { showsPreferences = true }
                }
            }
        }
        .task {
            let client = environment.services.apiClient ?? APIClient(configuration: APIConfiguration(baseURLString: "https://preview.invalid"))
            model.configure(api: NotificationsAPI(client: client), token: environment.accountSession.bearerToken,
                            unreadStore: environment.notificationUnread)
            await model.refresh()
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showsPreferences) {
            NotificationPreferencesView()
                .environmentObject(environment)
        }
    }
}

private struct NotificationPreferencesView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var values: NotificationPreferencesDTO?
    @State private var error: String?

    private var api: NotificationsAPI {
        NotificationsAPI(client: environment.services.apiClient ?? APIClient(configuration: APIConfiguration(baseURLString: "https://preview.invalid")))
    }

    var body: some View {
        NavigationStack {
            Group {
                if values != nil {
                    Form {
                        Toggle("New chapters", isOn: binding(\.libraryUpdates))
                        Toggle("Replies", isOn: binding(\.commentReplies))
                        Toggle("Mentions", isOn: binding(\.commentMentions))
                        Toggle("Likes", isOn: binding(\.commentLikes))
                        Toggle("Source status", isOn: binding(\.sourceStatus))
                        Toggle("Product announcements", isOn: binding(\.productAnnouncements))
                        Text("These switches control push alerts. Important events remain in Inbox.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } else if let error {
                    ContentUnavailableView(error, systemImage: "wifi.slash")
                } else { ProgressView() }
            }
            .navigationTitle("Notification preferences")
            .toolbar { Button("Done") { dismiss() } }
            .task {
                guard let token = environment.accountSession.bearerToken else { return }
                do { values = try await api.preferences(token: token) }
                catch { self.error = "Could not load preferences." }
            }
        }
    }

    private func binding(_ keyPath: WritableKeyPath<NotificationPreferencesDTO, Bool>) -> Binding<Bool> {
        Binding(get: { values?[keyPath: keyPath] ?? false }, set: { newValue in
            guard var current = values, let token = environment.accountSession.bearerToken else { return }
            let previous = current
            current[keyPath: keyPath] = newValue
            values = current
            Task {
                do { values = try await api.updatePreferences(current, token: token) }
                catch { values = previous; self.error = "Could not save preference." }
            }
        })
    }
}
