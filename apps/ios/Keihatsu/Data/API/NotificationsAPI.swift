import Foundation

nonisolated struct InboxNotificationDTO: Decodable, Identifiable, Sendable {
    let id: String
    let type: String
    let title: String
    let body: String
    let deepLink: String
    let sourceId: String?
    let mangaId: String?
    let chapterId: String?
    let commentId: String?
    let threadId: String?
    let createdAt: String
    var readAt: String?

    var date: Date { ISO8601DateFormatter().date(from: createdAt) ?? .now }
    var isRead: Bool { readAt != nil }
}

nonisolated struct InboxPageDTO: Decodable, Sendable {
    let items: [InboxNotificationDTO]
    let nextCursor: String?
}

nonisolated struct UnreadCountDTO: Decodable, Sendable { let count: Int }
nonisolated struct NotificationPreferencesDTO: Codable, Sendable {
    var libraryUpdates: Bool
    var commentReplies: Bool
    var commentMentions: Bool
    var commentLikes: Bool
    var moderation: Bool
    var sourceStatus: Bool
    var productAnnouncements: Bool
}

nonisolated struct NotificationsAPI: Sendable {
    let client: APIClient

    func list(token: String, cursor: String? = nil, category: String? = nil) async throws -> InboxPageDTO {
        var request = APIRequest<InboxPageDTO>(path: ["notifications"], requiresAuthentication: true)
        request.query = [ifLet(cursor, name: "cursor"), ifLet(category, name: "category")].compactMap { $0 }
        return try await client.send(request, bearerToken: token)
    }

    func unreadCount(token: String) async throws -> Int {
        try await client.send(APIRequest<UnreadCountDTO>(path: ["notifications", "unread-count"], requiresAuthentication: true), bearerToken: token).count
    }

    func markRead(_ id: String, token: String) async throws {
        let _: InboxNotificationDTO = try await client.send(APIRequest<InboxNotificationDTO>(
            path: ["notifications", id, "read"], method: .patch, requiresAuthentication: true), bearerToken: token)
    }

    func readAll(token: String) async throws {
        let _: UnreadCountDTO = try await client.send(APIRequest<UnreadCountDTO>(
            path: ["notifications", "read-all"], method: .post, requiresAuthentication: true), bearerToken: token)
    }

    func delete(_ id: String, token: String) async throws {
        let _: EmptyAPIResponse = try await client.send(APIRequest<EmptyAPIResponse>(
            path: ["notifications", id], method: .delete, requiresAuthentication: true), bearerToken: token)
    }

    func preferences(token: String) async throws -> NotificationPreferencesDTO {
        try await client.send(APIRequest<NotificationPreferencesDTO>(
            path: ["notifications", "preferences"], requiresAuthentication: true), bearerToken: token)
    }

    func updatePreferences(_ values: NotificationPreferencesDTO, token: String) async throws -> NotificationPreferencesDTO {
        try await client.send(APIRequest<NotificationPreferencesDTO>(
            path: ["notifications", "preferences"], method: .patch,
            body: JSONEncoder().encode(values), requiresAuthentication: true), bearerToken: token)
    }

    func register(token: String, installationID: String, deviceToken: String, version: String) async throws {
        let body = ["installationId": installationID, "platform": "IOS", "token": deviceToken, "appVersion": version]
        let _: EmptyAPIResponse = try await client.send(APIRequest<EmptyAPIResponse>(
            path: ["notifications", "devices"], method: .post,
            body: JSONEncoder().encode(body), requiresAuthentication: true), bearerToken: token)
    }

    func unregister(token: String, installationID: String) async throws {
        let _: EmptyAPIResponse = try await client.send(APIRequest<EmptyAPIResponse>(
            path: ["notifications", "devices", installationID], method: .delete, requiresAuthentication: true), bearerToken: token)
    }

    private func ifLet(_ value: String?, name: String) -> URLQueryItem? {
        value.map { URLQueryItem(name: name, value: $0) }
    }
}
