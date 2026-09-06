import Foundation

protocol AuthenticationServicing: Sendable {
    func exchangeGoogleToken(_ idToken: String) async throws -> (token: String, account: UserAccount)
    func currentAccount(token: String) async throws -> UserAccount
}

protocol UserServicing: Sendable {
    func statistics(token: String) async throws -> UserStatistics
    func preferences(token: String) async throws -> SyncedUserPreferences
    func updatePreferences(_ preferences: SyncedUserPreferences, token: String) async throws -> SyncedUserPreferences
    func updateProfile(_ update: ProfileUpdate, token: String) async throws -> UserAccount
    func updateVisibility(_ isPublic: Bool, token: String) async throws -> UserAccount
    func publicProfile(userID: String) async throws -> PublicUserProfile
}

protocol CommentsServicing: Sendable {
    func comments(chapter: ChapterIdentity, token: String?) async throws -> [ChapterComment]
    func createComment(chapter: ChapterIdentity, content: String, parentID: String?, images: [PendingCommentImage], token: String) async throws
    func toggleLike(commentID: String, token: String) async throws
    func deleteComment(commentID: String, token: String) async throws
}
