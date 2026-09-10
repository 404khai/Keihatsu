import Foundation

nonisolated struct LibraryAPI: Sendable {
    private struct CreateBody: Encodable {
        let mangaId: String
        let sourceId: String
        let title: String
        let thumbnailUrl: String?
        let author: String?
        let language: String?
    }
    private struct UpdateBody: Encodable {
        let isUnread: Bool
        let isStarted: Bool
        let isBookmarked: Bool
        let isCompleted: Bool
    }
    private struct CategoriesBody: Encodable { let categoryIds: [String] }
    private let client: APIClient
    init(client: APIClient) { self.client = client }

    func all(token: String) async throws -> [LibraryEntryDTO] {
        try await client.send(APIRequest<[LibraryEntryDTO]>(path: ["user", "library"], requiresAuthentication: true), bearerToken: token)
    }

    func add(_ manga: Manga, token: String) async throws -> LibraryEntryDTO {
        let body = try JSONEncoder().encode(CreateBody(
            mangaId: manga.id.mangaID, sourceId: manga.id.sourceID, title: manga.title,
            thumbnailUrl: manga.thumbnailURL?.absoluteString, author: manga.author, language: manga.language
        ))
        return try await client.send(
            APIRequest<LibraryEntryDTO>(path: ["user", "library"], method: .post, body: body, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func update(serverID: String, flags: (Bool, Bool, Bool, Bool), token: String) async throws {
        let body = try JSONEncoder().encode(UpdateBody(
            isUnread: flags.0, isStarted: flags.1, isBookmarked: flags.2, isCompleted: flags.3
        ))
        let _: LibraryEntryDTO = try await client.send(
            APIRequest<LibraryEntryDTO>(path: ["user", "library", serverID], method: .put, body: body, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func remove(serverID: String, token: String) async throws {
        let _: EmptyAPIResponse = try await client.send(
            APIRequest<EmptyAPIResponse>(path: ["user", "library", serverID], method: .delete, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func setCategories(serverID: String, categoryIDs: [String], token: String) async throws -> LibraryEntryDTO {
        let body = try JSONEncoder().encode(CategoriesBody(categoryIds: categoryIDs))
        return try await client.send(
            APIRequest<LibraryEntryDTO>(path: ["user", "library", serverID, "categories"], method: .put, body: body, requiresAuthentication: true),
            bearerToken: token
        )
    }
}
