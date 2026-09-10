import Foundation

nonisolated struct CategoriesAPI: Sendable {
    private struct NameBody: Encodable { let name: String }
    private let client: APIClient
    init(client: APIClient) { self.client = client }

    func all(token: String) async throws -> [CategoryDTO] {
        try await client.send(APIRequest<[CategoryDTO]>(path: ["user", "categories"], requiresAuthentication: true), bearerToken: token)
    }

    func create(name: String, token: String) async throws -> CategoryDTO {
        let body = try JSONEncoder().encode(NameBody(name: name))
        return try await client.send(
            APIRequest<CategoryDTO>(path: ["user", "categories"], method: .post, body: body, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func rename(serverID: String, name: String, token: String) async throws -> CategoryDTO {
        let body = try JSONEncoder().encode(NameBody(name: name))
        return try await client.send(
            APIRequest<CategoryDTO>(path: ["user", "categories", serverID], method: .put, body: body, requiresAuthentication: true),
            bearerToken: token
        )
    }

    func remove(serverID: String, token: String) async throws {
        let _: EmptyAPIResponse = try await client.send(
            APIRequest<EmptyAPIResponse>(path: ["user", "categories", serverID], method: .delete, requiresAuthentication: true),
            bearerToken: token
        )
    }
}
