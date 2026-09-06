import Foundation

nonisolated struct CommentsAPI: CommentsServicing, Sendable {
    private struct LikeResponse: Decodable, Sendable { let status: String }
    private let client: APIClient

    init(client: APIClient) { self.client = client }

    func comments(chapter: ChapterIdentity, token: String?) async throws -> [ChapterComment] {
        let request = APIRequest<[CommentDTO]>(
            path: ["comments", "source", chapter.manga.sourceID, chapter.manga.mangaID, chapter.chapterID],
            requiresAuthentication: token != nil
        )
        return try await client.send(request, bearerToken: token).map(\.domain)
    }

    func createComment(
        chapter: ChapterIdentity,
        content: String,
        parentID: String?,
        images: [PendingCommentImage],
        token: String
    ) async throws {
        var parts = [MultipartFormPart(name: "content", value: content)]
        if let parentID { parts.append(MultipartFormPart(name: "parentId", value: parentID)) }
        parts += images.map { MultipartFormPart(name: "images", data: $0.data, filename: $0.filename, contentType: $0.contentType) }
        let _: CommentDTO = try await client.sendMultipart(
            path: ["comments", "source", chapter.manga.sourceID, chapter.manga.mangaID, chapter.chapterID],
            method: .post,
            parts: parts,
            bearerToken: token
        )
    }

    func toggleLike(commentID: String, token: String) async throws {
        let _: LikeResponse = try await client.send(
            APIRequest<LikeResponse>(path: ["comments", commentID, "like"], method: .post, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func deleteComment(commentID: String, token: String) async throws {
        let _: EmptyAPIResponse = try await client.send(
            APIRequest<EmptyAPIResponse>(path: ["comments", commentID], method: .delete, requiresAuthentication: true),
            bearerToken: token
        )
    }
}
