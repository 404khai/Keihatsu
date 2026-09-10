import Foundation

nonisolated struct AuthAPI: AuthenticationServicing, Sendable {
    private struct GoogleBody: Encodable { let token: String }
    private let client: APIClient

    init(client: APIClient) { self.client = client }

    func exchangeGoogleToken(_ idToken: String) async throws -> (token: String, account: UserAccount) {
        let body = try JSONEncoder().encode(GoogleBody(token: idToken))
        let response = try await client.send(APIRequest<AuthResponseDTO>(path: ["auth", "google"], method: .post, body: body))
        return (response.accessToken, response.user.domain())
    }

    func currentAccount(token: String) async throws -> UserAccount {
        let dto = try await client.send(APIRequest<UserDTO>(path: ["auth", "me"], requiresAuthentication: true), bearerToken: token)
        return dto.domain()
    }
}
