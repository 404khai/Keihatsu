import Foundation

actor APIClient {
    private let configuration: APIConfiguration
    private let session: URLSession

    init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func send<Response>(_ endpoint: APIRequest<Response>, bearerToken: String? = nil) async throws -> Response {
        try Task.checkCancellation()
        let request = try endpoint.urlRequest(configuration: configuration, bearerToken: bearerToken)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (payload?["message"] as? String)
                ?? (payload?["message"] as? [String])?.joined(separator: "\n")
            throw APIError.http(status: http.statusCode, message: message)
        }
        let payload = data.isEmpty && Response.self == EmptyAPIResponse.self ? Data("{}".utf8) : data
        do {
            return try JSONDecoder().decode(Response.self, from: payload)
        } catch {
            throw APIError.decoding
        }
    }
}
