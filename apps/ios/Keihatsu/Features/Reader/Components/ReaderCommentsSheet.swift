import PhotosUI
import SwiftUI

struct ReaderCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var session: AccountSessionStore
    let manga: Manga
    let chapter: Chapter?
    @State private var model: CommentsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model { CommentsThreadView(model: model) }
                else { ContentUnavailableView("Comments unavailable", systemImage: "text.bubble", description: Text("Wait until a chapter is visible, then try again.")) }
            }
            .navigationTitle(chapter?.name ?? "Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .task(id: chapter?.id) {
            guard let chapter else { return }
            let value = CommentsViewModel(chapter: chapter.id, service: environment.commentsAPI, session: session)
            model = value
            await value.load()
        }
    }
}

private struct CommentsThreadView: View {
    @ObservedObject var model: CommentsViewModel
    @EnvironmentObject private var session: AccountSessionStore
    @State private var pickedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if model.isLoading && model.comments.isEmpty {
                    ProgressView("Loading discussion…")
                } else if model.comments.isEmpty {
                    ContentUnavailableView("No comments yet", systemImage: "text.bubble", description: Text("Start the discussion for this chapter."))
                } else {
                    List {
                        ForEach(model.comments) { comment in
                            CommentRow(comment: comment, depth: 0, model: model)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await model.load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(.red).padding(.horizontal).padding(.top, 8)
            }
            composer
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let reply = model.replyingTo {
                HStack {
                    Text("Replying to \(reply.author.username)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Cancel") { model.replyingTo = nil }.font(.caption)
                }
            }
            if !model.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(model.images) { image in
                            if let uiImage = UIImage(data: image.data) {
                                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 10) {
                PhotosPicker(selection: $pickedItems, maxSelectionCount: 5, matching: .images) {
                    Image(systemName: "photo.on.rectangle.angled").frame(width: 36, height: 36)
                }
                .disabled(!session.isAuthenticated)
                TextField(session.isAuthenticated ? "Add a comment" : "Sign in to comment", text: $model.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!session.isAuthenticated)
                Button { Task { await model.post() } } label: {
                    if model.isPosting { ProgressView() } else { Image(systemName: "arrow.up.circle.fill").font(.title) }
                }
                .disabled(!model.canPost)
                .accessibilityLabel("Post comment")
            }
        }
        .padding(12)
        .background(.bar)
        .onChange(of: pickedItems) { _, items in Task { await load(items) } }
    }

    private func load(_ items: [PhotosPickerItem]) async {
        var images: [PendingCommentImage] = []
        for (index, item) in items.prefix(5).enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self) {
                images.append(PendingCommentImage(data: data, filename: "comment-\(index).jpg", contentType: "image/jpeg"))
            }
        }
        model.images = images
    }
}

private struct CommentRow: View {
    let comment: ChapterComment
    let depth: Int
    @ObservedObject var model: CommentsViewModel
    @EnvironmentObject private var session: AccountSessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                NavigationLink { PublicProfileView(userID: comment.author.id) } label: {
                    UserAvatarView(seed: comment.author.id, label: comment.author.username, configuration: comment.author.avatar, size: depth == 0 ? 42 : 34)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 7) {
                    NavigationLink(comment.author.username) { PublicProfileView(userID: comment.author.id) }
                        .font(.subheadline.weight(.semibold))
                    if !comment.content.isEmpty { Text(comment.content).font(.body) }
                    if !comment.imageURLs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(comment.imageURLs, id: \.self) { url in
                                    AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { ProgressView() }
                                        .frame(width: 112, height: 112).clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    HStack(spacing: 16) {
                        Button { Task { await model.toggleLike(comment) } } label: {
                            Label("\(comment.likes)", systemImage: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                        }
                        Button("Reply") { model.replyingTo = comment }
                        if session.account?.id == comment.author.id {
                            Button("Delete", role: .destructive) { Task { await model.delete(comment) } }
                        }
                        Text(comment.createdAt.formatted(.relative(presentation: .named))).foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                }
            }
            ForEach(comment.replies) { reply in
                CommentRow(comment: reply, depth: min(depth + 1, 3), model: model).padding(.leading, 30)
            }
        }
        .padding(.vertical, 6)
    }
}
