import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AccountSessionStore
    let account: UserAccount

    @State private var username: String
    @State private var bio: String
    @State private var avatar: AvatarConfiguration
    @State private var isSaving = false
    @State private var error: String?

    init(account: UserAccount) {
        self.account = account
        _username = State(initialValue: account.username)
        _bio = State(initialValue: account.bio ?? "")
        _avatar = State(initialValue: account.avatar)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    UserAvatarView(seed: account.id, label: username, configuration: avatar, size: 132)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                Section("Profile") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...8)
                    Text("\(bio.count)/500").font(.caption).foregroundStyle(bio.count > 500 ? .red : .secondary)
                }
                Section("Blobatar") {
                    Picker("Hue", selection: $avatar.hue) {
                        Text("Automatic").tag(nil as Double?)
                        ForEach(stride(from: 0.0, to: 360.0, by: 45.0).map { $0 }, id: \.self) { hue in
                            Text("\(Int(hue))°").tag(Optional(hue))
                        }
                    }
                    Picker("Shape", selection: $avatar.shape) {
                        Text("Automatic").tag(nil as Double?)
                        ForEach([0.1, 0.3, 0.5, 0.7, 0.9], id: \.self) { shape in
                            Text("\(Int(shape * 100))%").tag(Optional(shape))
                        }
                    }
                    Picker("Expression", selection: $avatar.expression) {
                        ForEach(AvatarConfiguration.Expression.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Animated avatar", isOn: $avatar.animated)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(!isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private var isValid: Bool {
        let count = username.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (3...30).contains(count) && bio.count <= 500
    }

    private func save() async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            try await session.updateProfile(ProfileUpdate(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                avatar: avatar
            ))
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
