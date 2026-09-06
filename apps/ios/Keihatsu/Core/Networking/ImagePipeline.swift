import Foundation
import ImageIO
import UIKit

/// Public artwork only. No session token is sent to provider or image URLs.
@MainActor
final class ImagePipeline {
    private let configuration: APIConfiguration
    private let session: URLSession
    private var inFlight: [NSURL: Task<UIImage, Error>] = [:]
    private let decoded = NSCache<NSURL, UIImage>()

    init(configuration: APIConfiguration, session: URLSession? = nil) {
        self.configuration = configuration
        let settings = URLSessionConfiguration.default
        settings.urlCache = URLCache(memoryCapacity: 32 * 1_024 * 1_024, diskCapacity: 150 * 1_024 * 1_024, directory: nil)
        settings.httpMaximumConnectionsPerHost = 2
        settings.timeoutIntervalForRequest = 30
        self.session = session ?? URLSession(configuration: settings)
        decoded.totalCostLimit = 48 * 1_024 * 1_024
    }

    nonisolated static func request(url: URL, referer: URL?, configuration: APIConfiguration) throws -> URLRequest {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" || (configuration.allowsInsecureHTTP && scheme == "http"),
              let host = url.host?.lowercased(), url.user == nil, url.password == nil else { throw APIError.invalidBaseURL }
        let proxyHosts = ["manhuatop.org", "batcave.biz"]
        if scheme == "https", proxyHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
            let endpoint = APIRequest<EmptyAPIResponse>(path: ["sources", "proxy", "image"], query: [
                URLQueryItem(name: "url", value: url.absoluteString),
                URLQueryItem(name: "referer", value: referer?.absoluteString)
            ])
            var request = try endpoint.urlRequest(configuration: configuration)
            request.setValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }
        var request = URLRequest(url: url)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        return request
    }

    func image(url: URL, referer: URL?) async throws -> UIImage {
        try Task.checkCancellation()
        let request = try Self.request(url: url, referer: referer, configuration: configuration)
        let key = (request.url ?? url) as NSURL
        if let image = decoded.object(forKey: key) { return image }
        if let pending = inFlight[key] {
            let image = try await pending.value
            try Task.checkCancellation()
            return image
        }
        let task = Task { [session] in
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode), data.count <= 12 * 1_024 * 1_024,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1_200
                  ] as CFDictionary) else { throw APIError.invalidResponse }
            let image = UIImage(cgImage: thumbnail)
            decoded.setObject(image, forKey: key, cost: thumbnail.bytesPerRow * thumbnail.height)
            return image
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        let image = try await task.value
        try Task.checkCancellation()
        return image
    }
}
