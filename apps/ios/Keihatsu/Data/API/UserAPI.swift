import Foundation

nonisolated struct UserAPI: UserServicing, Sendable {
    private struct VisibilityBody: Encodable { let isProfilePublic: Bool }
    private let client: APIClient

    init(client: APIClient) { self.client = client }

    func statistics(token: String) async throws -> UserStatistics {
        let dto = try await client.send(
            APIRequest<UserStatisticsDTO>(path: ["user", "profile", "stats"], requiresAuthentication: true),
            bearerToken: token
        )
        return dto.domain
    }

    func preferences(token: String) async throws -> SyncedUserPreferences {
        let dto = try await client.send(
            APIRequest<UserPreferencesDTO>(path: ["user", "preferences"], requiresAuthentication: true),
            bearerToken: token
        )
        return dto.domain
    }

    func updatePreferences(_ preferences: SyncedUserPreferences, token: String) async throws -> SyncedUserPreferences {
        let body = try JSONEncoder().encode(UserPreferencesDTO(preferences))
        let dto = try await client.send(
            APIRequest<UserPreferencesDTO>(path: ["user", "preferences"], method: .put, body: body, requiresAuthentication: true),
            bearerToken: token
        )
        return dto.domain
    }

    func updateProfile(_ update: ProfileUpdate, token: String) async throws -> UserAccount {
        let parts = [
            MultipartFormPart(name: "username", value: update.username),
            MultipartFormPart(name: "bio", value: update.bio),
            MultipartFormPart(name: "avatarHue", value: update.avatar.hue.map { String($0) } ?? "auto"),
            MultipartFormPart(name: "avatarShape", value: update.avatar.shape.map { String($0) } ?? "auto"),
            MultipartFormPart(name: "avatarExpression", value: update.avatar.expression.rawValue),
            MultipartFormPart(name: "avatarAnimated", value: String(update.avatar.animated))
        ]
        let dto: UserDTO = try await client.sendMultipart(
            path: ["user", "profile"], method: .patch, parts: parts, bearerToken: token
        )
        return dto.domain()
    }

    func updateVisibility(_ isPublic: Bool, token: String) async throws -> UserAccount {
        let body = try JSONEncoder().encode(VisibilityBody(isProfilePublic: isPublic))
        let dto = try await client.send(
            APIRequest<UserDTO>(path: ["user", "profile", "visibility"], method: .patch, body: body, requiresAuthentication: true),
            bearerToken: token
        )
        return dto.domain()
    }

    func publicProfile(userID: String) async throws -> PublicUserProfile {
        let dto = try await client.send(APIRequest<PublicProfileDTO>(path: ["user", "profile", "public", userID]))
        return dto.domain
    }
}
