import SwiftUI
import UIKit

struct ProfilePageContent: View {
    @EnvironmentObject private var accountSession: AccountSessionStore
    @EnvironmentObject private var bootstrap: AppBootstrap
    @EnvironmentObject private var downloads: DownloadCoordinator
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @State private var showsInbox = false
    @State private var showsSignIn = false
    @State private var showsEditProfile = false
    @State private var showsCategories = false
    @State private var confirmsLogout = false
    @State private var confirmsAccountDeletion = false
    @State private var isDeletingAccount = false
    @State private var accountDeletionError: String?
    @State private var showsToolbarAvatar = false

    private var account: UserAccount? { accountSession.account }
    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }
    private var activeDownloadCount: Int { downloads.activeRecords.filter { $0.status.isActive }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                profileHeader
                statsCard
                ProfileGroup {
                    NavigationLink { DownloadQueueView() } label: {
                        ProfileRow(
                            icon: "icloud.and.arrow.down",
                            title: "Download Queue",
                            showsChevron: true,
                            badgeCount: activeDownloadCount,
                            badgeColor: accent
                        )
                    }
                    .buttonStyle(.plain)
                }
                ProfileGroup {
                    NavigationLink { SettingsView() } label: { ProfileRow(icon: "gearshape", title: "Settings", showsChevron: true) }
                        .buttonStyle(.plain)
                    ProfileDivider()
                    NavigationLink { StatsView() } label: { ProfileRow(icon: "chart.bar", title: "Stats", showsChevron: true) }
                        .buttonStyle(.plain)
                    ProfileDivider()
                    Button { showsInbox = true } label: { ProfileRow(icon: "tray", title: "Inbox", showsChevron: true) }
                        .buttonStyle(.plain)
                }
                ProfileGroup {
                    Button { showsCategories = true } label: {
                        ProfileRow(icon: "tag", title: "Categories", showsChevron: true)
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                    NavigationLink { DataStorageView() } label: {
                        ProfileRow(icon: "server.rack", title: "Data & Storage", showsChevron: true)
                    }
                    .buttonStyle(.plain)
                }
                ProfileGroup {
                    NavigationLink { SupportDeveloperView() } label: {
                        ProfileRow(icon: "gift", title: "Support the Developer", showsChevron: true)
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                    NavigationLink { HelpAndSupportView() } label: { ProfileRow(icon: "questionmark.circle", title: "Help & Support", showsChevron: true) }
                        .buttonStyle(.plain)
                    ProfileDivider()
                    NavigationLink { AboutView() } label: { ProfileRow(icon: "info.circle", title: "About", showsChevron: true) }
                        .buttonStyle(.plain)
                }
                ProfileGroup {
                    HStack(spacing: 18) {
                        ProfileIcon(symbol: "theatermasks.fill")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Incognito Mode").font(.title3.weight(.medium)).fontDesign(.rounded)
                            Text("Read without saving history").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 12)
                        Toggle("Incognito Mode", isOn: $preferencesStore.preferences.incognitoModeEnabled)
                            .labelsHidden()
                            .tint(accent)
                    }
                    .padding(18)
                }
                sessionButton
                if account != nil { deleteAccountButton }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 34)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 90
        } action: { _, shouldShow in
            guard shouldShow != showsToolbarAvatar else { return }

            withAnimation(.snappy(duration: 0.25)) {
                showsToolbarAvatar = shouldShow
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if showsToolbarAvatar {
                    HStack(spacing: 10) {
                        UserAvatarView(
                            seed: account?.id ?? "keihatsu-guest",
                            label: account?.username ?? "Guest Reader",
                            configuration: account?.avatar ?? .default,
                            size: 40
                        )
                        Text(account?.username ?? "Guest Reader")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
//        .background(Color(.systemGroupedBackground).ignoresSafeArea())
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .refreshable { await accountSession.refreshProfile() }
        .sheet(isPresented: $showsInbox) { NotificationsSheetView(title: "Inbox") }
        .sheet(isPresented: $showsSignIn) {
            AccountEntryView(onSignedIn: { showsSignIn = false }, onContinueAsGuest: { showsSignIn = false })
        }
        .sheet(isPresented: $showsEditProfile) {
            if let account { EditProfileView(account: account) }
        }
        .sheet(isPresented: $showsCategories) { LibraryCategoriesSheet() }
        .sheet(isPresented: $confirmsLogout) {
            logoutSheet
                .presentationDetents([.height(370)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $confirmsAccountDeletion) {
            deleteAccountSheet
                .interactiveDismissDisabled(isDeletingAccount)
                .presentationDetents([.height(410)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemGroupedBackground))
        }
        .alert("Account Deletion Failed", isPresented: Binding(
            get: { accountDeletionError != nil },
            set: { if !$0 { accountDeletionError = nil } }
        )) {
            Button("OK") { accountDeletionError = nil }
        } message: {
            Text(accountDeletionError ?? "Please try again.")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            UserAvatarView(seed: account?.id ?? "keihatsu-guest", label: account?.username ?? "Guest Reader", configuration: account?.avatar ?? .default, size: 100)
            VStack(spacing: 8) {
                Text(account?.username ?? "Guest Reader")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text(profileSubtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let joined = account?.createdAt {
                    Label("Member since \(joined.formatted(.dateTime.year()))", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            if account != nil {
                HStack(spacing: 12) {
                    Button { showsEditProfile = true } label: {
                        Label("Edit Profile", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)

                    Menu {
                        Button {
                            UIPasteboard.general.string = profileURL.absoluteString
                        } label: {
                            Label("Copy Profile Link", systemImage: "doc.on.doc")
                        }

                        ShareLink(item: profileURL) {
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                        }

                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.glass)
//                    .glassEffect(.regular, in: .circle)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Copy or share profile")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var profileSubtitle: String {
        if let bio = account?.bio?.trimmingCharacters(in: .whitespacesAndNewlines), !bio.isEmpty { return bio }
        return account == nil ? "Sign in to sync your reading journey." : "Keihatsu reader"
    }

    private var profileURL: URL {
        let slug = account?.username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? account?.id ?? "reader"
        return URL(string: "https://keihatsu.app/u/\(slug)")!
    }

    private var statsCard: some View {
        let stats = account?.statistics ?? .empty
        return HStack(spacing: 0) {
            ProfileStat(value: "\(stats.libraryCount)", label: "in Library")
            ProfileStat(value: readingTime(stats.totalReadingTimeMinutes), label: "reading")
            ProfileStat(value: "\(stats.mangasReadToday)", label: "today")
            ProfileStat(value: "\(stats.commentsCount)", label: "comments", showsDivider: false)
        }
        .padding(.vertical, 18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var sessionButton: some View {
        Button(role: account == nil ? nil : .destructive) {
            if account == nil { showsSignIn = true } else { confirmsLogout = true }
        } label: {
            Text(account == nil ? "Sign In" : "Log Out").font(.title3.weight(.semibold)).fontDesign(.rounded).frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var logoutSheet: some View {
        VStack(spacing: 22) {
            sheetIcon("rectangle.portrait.and.arrow.right", color: accent)

            VStack(spacing: 8) {
                Text("Sign out of Keihatsu?")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                Text("Your library and history will be detached from this device until you sign in again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(role: .destructive) {
                    confirmsLogout = false
                    Task {
                        await accountSession.logout()
                        bootstrap.requireAccountEntry()
                    }
                } label: {
                    sheetButtonLabel("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.red)

                Button { confirmsLogout = false } label: {
                    sheetButtonLabel("Cancel")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(accent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 20)
    }

    private var deleteAccountSheet: some View {
        VStack(spacing: 22) {
            sheetIcon("trash.fill", color: .red)

            VStack(spacing: 8) {
                Text("Delete your account?")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                Text("Your profile, library, categories, history, comments, and preferences will be permanently deleted. This cannot be undone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(role: .destructive) {
                    Task { await deleteAccount() }
                } label: {
                    if isDeletingAccount {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Deleting Account…")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                    } else {
                        sheetButtonLabel("Delete Account", systemImage: "trash")
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.red)
                .disabled(isDeletingAccount)

                Button { confirmsAccountDeletion = false } label: {
                    sheetButtonLabel("Cancel")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(accent)
                .disabled(isDeletingAccount)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 20)
    }

    private func sheetIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 64, height: 64)
            .background(color.opacity(0.14), in: Circle())
    }

    private func sheetButtonLabel(_ title: String, systemImage: String? = nil) -> some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity, minHeight: 52)
    }

    private var deleteAccountButton: some View {
        Button(role: .destructive) { confirmsAccountDeletion = true } label: {
            HStack(spacing: 10) {
                if isDeletingAccount { ProgressView() }
                Image(systemName: "trash")
                Text(isDeletingAccount ? "Deleting Account…" : "Delete Account")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.rounded)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(isDeletingAccount)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func deleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await accountSession.deleteAccount()
            confirmsAccountDeletion = false
            bootstrap.requireAccountEntry()
        } catch {
            accountDeletionError = error.localizedDescription
        }
    }

    private func readingTime(_ minutes: Int) -> String { minutes >= 60 ? "\(minutes / 60)h" : "\(minutes)m" }
}

struct ProfileGroup<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(spacing: 0) { content }.background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous)) }
}

struct ProfileDivider: View { var body: some View { Divider().padding(.horizontal, 18) } }

struct ProfileRow: View {
    let icon: String
    let title: String
    var showsChevron = false
    var badgeCount: Int = 0
    var badgeColor: Color = .accentColor
    var body: some View {
        HStack(spacing: 18) {
            ProfileIcon(symbol: icon)
            Text(title).font(.title3.weight(.medium)).fontDesign(.rounded)
            Spacer()
            if badgeCount > 0 {
                Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(minWidth: 24, minHeight: 24)
                    .background(badgeColor, in: Capsule())
                    .accessibilityLabel("\(badgeCount) active downloads")
            }
            if showsChevron { Image(systemName: "chevron.right").foregroundStyle(.tertiary) }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
    }
}

struct ProfileIcon: View {
    let symbol: String
    var body: some View { Image(systemName: symbol).font(.title2.weight(.medium)).symbolRenderingMode(.hierarchical).frame(width: 38, height: 38) }
}

private struct ProfileStat: View {
    let value: String
    let label: String
    var showsDivider = true
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(value).font(.title.bold()).fontDesign(.rounded)
                Text(label).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            if showsDivider { Divider().frame(height: 42) }
        }
    }
}
