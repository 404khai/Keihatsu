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

    private static let shapes = [
        AvatarShapeOption(label: "Original", value: nil),
        AvatarShapeOption(label: "Round", value: 0.11),
        AvatarShapeOption(label: "Organic", value: 0.35),
        AvatarShapeOption(label: "Boxy", value: 0.54),
        AvatarShapeOption(label: "Capsule", value: 0.65),
        AvatarShapeOption(label: "Nub", value: 0.745),
        AvatarShapeOption(label: "Cloud", value: 0.825),
        AvatarShapeOption(label: "Droplet", value: 0.888),
        AvatarShapeOption(label: "Hexagon", value: 0.933),
        AvatarShapeOption(label: "Sun", value: 0.965),
        AvatarShapeOption(label: "Triangle", value: 0.99)
    ]
    private static let hues: [Double?] = [nil] + stride(from: 0.0, to: 360.0, by: 15.0).map { Optional($0) }

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
                    VStack(spacing: 10) {
                        UserAvatarView(
                            seed: account.id,
                            label: username,
                            configuration: avatar,
                            size: 132
                        )
                        Text("Your Blobatar is generated from your Keihatsu account and stays identical across Flutter and iOS.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section("Profile") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...8)
                    Text("\(bio.count)/500")
                        .font(.caption)
                        .foregroundStyle(bio.count > 500 ? .red : .secondary)
                }

                Section("Shape") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Self.shapes) { option in
                                shapeButton(option)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
                }

                Section("Color") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                        spacing: 12
                    ) {
                        ForEach(Self.hues, id: \.self) { hue in
                            hueButton(hue)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Expression") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AvatarConfiguration.Expression.allCases) { expression in
                                expressionButton(expression)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
                }

                Section {
                    Toggle("Animated avatar", isOn: $avatar.animated)
                } footer: {
                    Text("Enable Blobatar breathing, blinking, and ambient motion.")
                }

                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(!isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func shapeButton(_ option: AvatarShapeOption) -> some View {
        var preview = avatar
        preview.shape = option.value
        preview.animated = false

        return Button {
            avatar.shape = option.value
        } label: {
            AvatarChoiceLabel(
                label: option.label,
                selected: approximatelyEqual(avatar.shape, option.value)
            ) {
                UserAvatarView(
                    seed: account.id,
                    label: "\(option.label) shape",
                    configuration: preview,
                    size: 54
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.label) shape")
        .accessibilityAddTraits(approximatelyEqual(avatar.shape, option.value) ? .isSelected : [])
    }

    private func hueButton(_ hue: Double?) -> some View {
        let selected = approximatelyEqual(avatar.hue, hue)
        let label = hue.map { "Hue \(Int($0)) degrees" } ?? "Original color"

        return Button {
            avatar.hue = hue
        } label: {
            ZStack {
                Circle()
                    .fill(hue.map { color(for: $0) } ?? Color(.tertiarySystemFill))
                if hue == nil {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                } else if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                }
            }
            .frame(width: 38, height: 38)
            .overlay {
                Circle()
                    .stroke(selected ? Color.accentColor : .clear, lineWidth: 3)
                    .padding(-3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func expressionButton(_ expression: AvatarConfiguration.Expression) -> some View {
        var preview = avatar
        preview.expression = expression
        preview.animated = false

        return Button {
            avatar.expression = expression
        } label: {
            AvatarChoiceLabel(label: expression.label, selected: avatar.expression == expression) {
                UserAvatarView(
                    seed: account.id,
                    label: "\(expression.label) expression",
                    configuration: preview,
                    size: 54
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(expression.label) expression")
        .accessibilityAddTraits(avatar.expression == expression ? .isSelected : [])
    }

    private func color(for hue: Double) -> Color {
        Color(hue: hue / 360, saturation: 0.68, brightness: 0.92)
    }

    private func approximatelyEqual(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (.some(lhs), .some(rhs)): abs(lhs - rhs) < 0.000_1
        default: false
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
            try await session.updateProfile(
                ProfileUpdate(
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatar: avatar
                )
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct AvatarShapeOption: Identifiable {
    let label: String
    let value: Double?
    var id: String { label }
}

private struct AvatarChoiceLabel<Content: View>: View {
    let label: String
    let selected: Bool
    let content: Content

    init(label: String, selected: Bool, @ViewBuilder content: () -> Content) {
        self.label = label
        self.selected = selected
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 5) {
            content
            Text(label)
                .font(.caption2.weight(selected ? .bold : .medium))
                .foregroundStyle(selected ? Color.accentColor : .secondary)
                .lineLimit(1)
        }
        .frame(width: 78, height: 88)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Color.accentColor : .clear, lineWidth: 2)
        }
    }
}
