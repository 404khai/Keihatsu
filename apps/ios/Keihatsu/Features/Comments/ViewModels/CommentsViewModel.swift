import Combine
import Foundation

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published private(set) var comments: [ChapterComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPosting = false
    @Published var error: String?
    @Published var draft = ""
    @Published var images: [PendingCommentImage] = []
    @Published var replyingTo: ChapterComment?

    let chapter: ChapterIdentity
    private let service: any CommentsServicing
    private let session: AccountSessionStore

    init(chapter: ChapterIdentity, service: any CommentsServicing, session: AccountSessionStore) {
        self.chapter = chapter
        self.service = service
        self.session = session
    }

    var canPost: Bool {
        session.isAuthenticated && !isPosting && (!draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty)
    }

    func load(showProgress: Bool = true) async {
        if showProgress { isLoading = true }
        defer { isLoading = false }
        do {
            comments = try await service.comments(chapter: chapter, token: session.bearerToken)
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    func post() async {
        guard let token = session.bearerToken, canPost else { return }
        isPosting = true
        error = nil
        defer { isPosting = false }
        do {
            try await service.createComment(
                chapter: chapter,
                content: draft.trimmingCharacters(in: .whitespacesAndNewlines),
                parentID: replyingTo?.id,
                images: Array(images.prefix(5)),
                token: token
            )
            draft = ""
            images = []
            replyingTo = nil
            await load(showProgress: false)
            await session.refreshProfile()
        } catch { self.error = "Your comment may not have been posted. Check the thread before retrying. \(error.localizedDescription)" }
    }

    func toggleLike(_ comment: ChapterComment) async {
        guard let token = session.bearerToken else { error = "Sign in to like comments."; return }
        do { try await service.toggleLike(commentID: comment.id, token: token); await load(showProgress: false) }
        catch { self.error = "The like was not retried automatically. \(error.localizedDescription)" }
    }

    func delete(_ comment: ChapterComment) async {
        guard let token = session.bearerToken else { return }
        do { try await service.deleteComment(commentID: comment.id, token: token); await load(showProgress: false) }
        catch { self.error = error.localizedDescription }
    }
}
