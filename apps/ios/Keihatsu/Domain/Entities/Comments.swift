import Foundation

nonisolated struct CommentAuthor: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var username: String
    var avatar: AvatarConfiguration
}

nonisolated struct ChapterComment: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let content: String
    let imageURLs: [URL]
    let author: CommentAuthor
    let createdAt: Date
    let updatedAt: Date
    var likes: Int
    var isLikedByCurrentUser: Bool
    var replies: [ChapterComment]
}

nonisolated struct PendingCommentImage: Identifiable, Equatable, Sendable {
    let id: UUID
    let data: Data
    let filename: String
    let contentType: String

    init(id: UUID = UUID(), data: Data, filename: String, contentType: String) {
        self.id = id
        self.data = data
        self.filename = filename
        self.contentType = contentType
    }
}
