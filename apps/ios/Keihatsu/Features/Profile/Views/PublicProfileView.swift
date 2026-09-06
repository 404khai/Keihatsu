import SwiftUI

struct PublicProfileView: View {
    @EnvironmentObject private var session: AccountSessionStore
    let userID: String
    @State private var profile: PublicUserProfile?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            if isLoading && profile == nil {
                ProgressView("Loading profile…").padding(.top, 80)
            } else if let profile {
                VStack(spacing: 22) {
                    UserAvatarView(seed: profile.id, label: profile.account.username, configuration: profile.account.avatar, size: 112)
                    Text(profile.account.username).font(.largeTitle.bold()).fontDesign(.rounded)
                    if let bio = profile.account.bio, !bio.isEmpty { Text(bio).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                    if profile.account.isProfilePublic {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 14)], spacing: 18) {
                            ForEach(profile.library) { entry in
                                VStack(alignment: .leading, spacing: 8) {
                                    CatalogueCover(url: entry.manga.thumbnailURL, referer: entry.manga.url)
                                        .frame(height: 190)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    Text(entry.manga.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView("Private Library", systemImage: "lock", description: Text("This reader has chosen not to share their library."))
                    }
                }
                .padding(20)
            } else if let error {
                ContentUnavailableView {
                    Label("Profile unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: { Text(error) } actions: { Button("Retry") { Task { await load() } } }
            }
        }
        .navigationTitle("Reader Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: userID) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { profile = try await session.publicProfile(userID: userID); error = nil }
        catch { self.error = error.localizedDescription }
    }
}
