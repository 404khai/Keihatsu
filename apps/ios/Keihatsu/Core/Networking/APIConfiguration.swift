import Foundation

nonisolated struct APIConfiguration: Sendable {
    let baseURLString: String?
    let allowsInsecureHTTP: Bool
    let timeout: TimeInterval

    init(baseURLString: String?, allowsInsecureHTTP: Bool = false, timeout: TimeInterval = 30) {
        self.baseURLString = baseURLString
        self.allowsInsecureHTTP = allowsInsecureHTTP
        self.timeout = timeout
    }

    static func application(bundle: Bundle = .main, environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        #if DEBUG
        let allowsHTTP = true
        #else
        let allowsHTTP = false
        #endif
        return Self(
            baseURLString: environment["KEIHATSU_API_BASE_URL"]
                ?? bundle.object(forInfoDictionaryKey: "KEIHATSU_API_BASE_URL") as? String,
            allowsInsecureHTTP: allowsHTTP
        )
    }

    func origin() throws -> URLComponents {
        guard let value = baseURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty, !value.contains("$(") else {
            throw APIError.missingConfiguration
        }
        guard let url = URLComponents(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || (allowsInsecureHTTP && scheme == "http"),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
            throw APIError.invalidBaseURL
        }
        return url
    }
}
