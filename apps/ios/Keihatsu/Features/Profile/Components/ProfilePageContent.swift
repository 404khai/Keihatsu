import SwiftUI

struct ProfilePageContent: View {
    @EnvironmentObject private var accountSession: AccountSessionStore
    @EnvironmentObject private var bootstrap: AppBootstrap
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @State private var showsInbox = false
    @State private var showsSignIn = false
    @State private var showsEditProfile = false
    @State private var confirmsLogout = false

    private var account: UserAccount? { accountSession.account }
    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                profileHeader
                statsCard
                ProfileGroup { ProfileRow(icon: "icloud.and.arrow.down", title: "Download Queue", showsChevron: true) }
                ProfileGroup {
                    NavigationLink { SettingsView() } label: { ProfileRow(icon: "gearshape", title: "Settings", showsChevron: true) }
                        .buttonStyle(.plain)
                    ProfileDivider()
                    ProfileRow(icon: "chart.bar", title: "Stats", showsChevron: true)
                    ProfileDivider()
                    Button { showsInbox = true } label: { ProfileRow(icon: "tray", title: "Inbox", showsChevron: true) }
                        .buttonStyle(.plain)
                }
                ProfileGroup {
                    ProfileRow(icon: "tag", title: "Categories", showsChevron: true)
                    ProfileDivider()
                    ProfileRow(icon: "server.rack", title: "Data & Storage", showsChevron: true)
                }
                ProfileGroup {
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 34)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await accountSession.refreshProfile() }
        .sheet(isPresented: $showsInbox) { NotificationsSheetView(title: "Inbox") }
        .sheet(isPresented: $showsSignIn) {
            AccountEntryView(onSignedIn: { showsSignIn = false }, onContinueAsGuest: { showsSignIn = false })
        }
        .sheet(isPresented: $showsEditProfile) {
            if let account { EditProfileView(account: account) }
        }
        .confirmationDialog("Sign out of Keihatsu?", isPresented: $confirmsLogout) {
            Button("Sign Out", role: .destructive) {
                Task { await accountSession.logout(); bootstrap.requireAccountEntry() }
            }
        } message: {
            Text("This account’s library and history will be detached from the app until the next sign-in.")
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
                Button { showsEditProfile = true } label: {
                    Label("Edit Profile", systemImage: "pencil").font(.headline).frame(maxWidth: .infinity).frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var profileSubtitle: String {
        if let bio = account?.bio?.trimmingCharacters(in: .whitespacesAndNewlines), !bio.isEmpty { return bio }
        return account == nil ? "Sign in to sync your reading journey." : "Keihatsu reader"
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
    var body: some View {
        HStack(spacing: 18) {
            ProfileIcon(symbol: icon)
            Text(title).font(.title3.weight(.medium)).fontDesign(.rounded)
            Spacer()
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
