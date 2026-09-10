import Foundation

nonisolated struct CommentDTO: Decodable, Sendable {
    struct LikeDTO: Decodable, Sendable { let id: String }

    let id: String
    let content: String?
    let images: [String]?
    let userId: String
    let user: UserDTO?
    let createdAt: String
    let updatedAt: String
    let likes: Int?
    let replies: [CommentDTO]?
    let userLikes: [LikeDTO]?

    var domain: ChapterComment {
        let account = user?.domain() ?? UserAccount(
            id: userId, email: nil, username: "Reader", bio: nil, createdAt: nil,
            isProfilePublic: true, avatar: .default, statistics: .empty
        )
        return ChapterComment(
            id: id,
            content: content ?? "",
            imageURLs: (images ?? []).compactMap(URL.init(string:)),
            author: CommentAuthor(id: account.id, username: account.username, avatar: account.avatar),
            createdAt: APIDate.parse(createdAt) ?? .distantPast,
            updatedAt: APIDate.parse(updatedAt) ?? .distantPast,
            likes: likes ?? 0,
            isLikedByCurrentUser: !(userLikes ?? []).isEmpty,
            replies: (replies ?? []).map(\.domain)
        )
    }
}
