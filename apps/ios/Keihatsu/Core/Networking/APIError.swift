import Foundation

nonisolated enum APIError: Error, LocalizedError, Equatable, Sendable {
    case missingConfiguration, invalidBaseURL, invalidPath, authenticationRequired, invalidResponse, decoding
    case http(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration: return "The API address has not been configured."
        case .invalidBaseURL: return "The API address is invalid or uses an unsupported connection."
        case .invalidPath: return "The requested content address is invalid."
        case .authenticationRequired: return "Sign in to continue."
        case .invalidResponse: return "The server returned an invalid response."
        case .decoding: return "The server response could not be read."
        case .http(let status, let message): return message ?? "The request failed (\(status))."
        }
    }
}
