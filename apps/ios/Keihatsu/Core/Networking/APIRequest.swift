import Foundation

nonisolated struct APIRequest<Response: Decodable & Sendable>: Sendable {
    enum Method: String, Sendable {
        case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
    }

    let path: [String]
    var query: [URLQueryItem] = []
    var method: Method = .get
    var body: Data? = nil
    var requiresAuthentication = false

    func urlRequest(configuration: APIConfiguration, bearerToken: String? = nil) throws -> URLRequest {
        var components = try configuration.origin()
        // Treat each opaque source ID as one segment, including embedded URLs and percent signs.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let segments = try path.map { segment in
            guard !segment.isEmpty, segment != ".", segment != "..",
                  let encoded = segment.addingPercentEncoding(withAllowedCharacters: allowed) else {
                throw APIError.invalidPath
            }
            return encoded
        }
        let basePath = components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.percentEncodedPath = "/" + ([basePath].filter { !$0.isEmpty } + segments).joined(separator: "/")
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw APIError.invalidPath }
        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if requiresAuthentication {
            guard let bearerToken, !bearerToken.isEmpty else { throw APIError.authenticationRequired }
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

nonisolated struct EmptyAPIResponse: Decodable, Sendable {}
