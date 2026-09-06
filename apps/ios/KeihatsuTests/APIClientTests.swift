import Foundation
import Testing
@testable import Keihatsu

@Suite(.serialized)
struct APIClientTests {
    @Test func decodesSuccessAndNoContent() async throws {
        let client = makeClient(status: 201, body: "{\"mangas\":[],\"hasNextPage\":false}")
        let result = try await client.send(APIRequest<MangaPageDTO>(path: ["sources"]))
        #expect(result.mangas.isEmpty && !result.hasNextPage)
        let emptyClient = makeClient(status: 204, body: "")
        _ = try await emptyClient.send(APIRequest<EmptyAPIResponse>(path: ["user", "library", "id"], method: .delete))
    }

    @Test func preservesValidationErrorsAndDoesNotRetryWrites() async throws {
        let client = makeClient(status: 400, body: "{\"message\":[\"name is required\",\"name must be a string\"]}")
        await #expect(throws: APIError.http(status: 400, message: "name is required\nname must be a string")) {
            try await client.send(APIRequest<EmptyAPIResponse>(path: ["user", "categories"], method: .post))
        }
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test func rejectsMalformedJSONAndPreservesUnauthorizedStatus() async throws {
        let client = makeClient(status: 200, body: "not json")
        await #expect(throws: APIError.decoding) { try await client.send(APIRequest<MangaPageDTO>(path: ["sources"])) }
        let unauthorized = makeClient(status: 401, body: "{}")
        await #expect(throws: APIError.http(status: 401, message: nil)) { try await unauthorized.send(APIRequest<EmptyAPIResponse>(path: ["auth", "me"])) }
    }

    private func makeClient(status: Int, body: String) -> APIClient {
        StubURLProtocol.status = status
        StubURLProtocol.body = Data(body.utf8)
        StubURLProtocol.requestCount = 0
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(configuration: APIConfiguration(baseURLString: "https://api.example.test"), session: URLSession(configuration: configuration))
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var requestCount = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requestCount += 1
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
