import Foundation
import Testing
@testable import Keihatsu

@Suite(.serialized) @MainActor
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

    @Test func liveCatalogueUsesPublicRoutesAndPreservesDiskCacheAfterFailure() async throws {
        let client = makeClient(status: 200, body: "[{\"id\":\"manhuatop\",\"name\":\"ManhuaTop\",\"lang\":\"en\",\"baseUrl\":\"https://manhuatop.org\",\"versionId\":1}]")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = CatalogueCache(namespace: "test-origin", directory: directory)
        let repository = LiveCatalogueRepository(client: client, cache: cache)
        #expect(try await repository.sources().count == 1)
        #expect(StubURLProtocol.lastRequest?.url?.path == "/sources")
        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
        StubURLProtocol.status = 503
        await #expect(throws: APIError.self) { try await repository.sources() }
        let restoredCache = CatalogueCache(namespace: "test-origin", directory: directory)
        #expect(await restoredCache.read("sources", as: [Source].self)?.first?.id == "manhuatop")
        let otherOrigin = CatalogueCache(namespace: "other-origin", directory: directory)
        #expect(await otherOrigin.read("sources", as: [Source].self) == nil)
        StubURLProtocol.status = 200
        StubURLProtocol.body = Data("{\"mangas\":[],\"hasNextPage\":false}".utf8)
        _ = try await repository.mangas(sourceID: "manhuatop", listing: .search, page: 2, query: "a & b/é")
        let url = try #require(StubURLProtocol.lastRequest?.url)
        #expect(url.path == "/sources/manhuatop/manga")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(query?.first(where: { $0.name == "q" })?.value == "a & b/é")
        #expect(query?.first(where: { $0.name == "page" })?.value == "2")
        #expect(await repository.cachedMangas(sourceID: "manhuatop", listing: .search, page: 2, query: "a & b/é")?.hasNextPage == false)
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
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var requestCount = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastRequest = request
        Self.requestCount += 1
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
