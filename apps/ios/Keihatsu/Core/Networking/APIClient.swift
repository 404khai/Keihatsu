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
        return try decode(data)
    }

    func sendMultipart<Response: Decodable & Sendable>(
        path: [String],
        method: APIRequest<Response>.Method,
        parts: [MultipartFormPart],
        bearerToken: String
    ) async throws -> Response {
        let boundary = "keihatsu-\(UUID().uuidString)"
        let endpoint = APIRequest<Response>(path: path, method: method, requiresAuthentication: true)
        var request = try endpoint.urlRequest(configuration: configuration, bearerToken: bearerToken)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.multipartBody(parts: parts, boundary: boundary)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (payload?["message"] as? String)
                ?? (payload?["message"] as? [String])?.joined(separator: "\n")
            throw APIError.http(status: http.statusCode, message: message)
        }
        return try decode(data)
    }

    private func decode<Response: Decodable & Sendable>(_ data: Data) throws -> Response {
        let payload = data.isEmpty && Response.self == EmptyAPIResponse.self ? Data("{}".utf8) : data
        do {
            return try JSONDecoder().decode(Response.self, from: payload)
        } catch {
            throw APIError.decoding
        }
    }

    nonisolated private static func multipartBody(parts: [MultipartFormPart], boundary: String) -> Data {
        var body = Data()
        for part in parts {
            body.append(Data("--\(boundary)\r\n".utf8))
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let filename = part.filename { disposition += "; filename=\"\(filename)\"" }
            body.append(Data("\(disposition)\r\n".utf8))
            if let contentType = part.contentType {
                body.append(Data("Content-Type: \(contentType)\r\n".utf8))
            }
            body.append(Data("\r\n".utf8))
            body.append(part.value)
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }
}
