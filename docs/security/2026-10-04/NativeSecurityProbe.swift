// Compiled alongside the actual app storage/networking implementations.
// Success means current vulnerable behavior was reproduced.
import Foundation

@main struct NativeSecurityProbe {
    static func main() async throws {
        let fm = FileManager.default
        let sandbox = fm.temporaryDirectory.appending(path: "keihatsu-security-\(UUID())")
        let docs = sandbox.appending(path: "Documents")
        try fm.createDirectory(at: docs.appending(path: "downloads"), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: sandbox) }
        let store = ChapterArchiveStore(documentsRoot: docs, applicationSupportRoot: sandbox.appending(path: "Support"))
        let identity = DownloadIdentity(sourceID: "..", mangaID: "..", chapterID: "victim")
        let target = await store.archiveURL(for: identity)
        let victim = sandbox.appending(path: "victim.cbz")
        precondition(target.standardizedFileURL == victim.standardizedFileURL)
        try Data("test sentinel".utf8).write(to: victim)
        try await store.delete(identity)
        precondition(!fm.fileExists(atPath: victim.path))
        print("SEC-04 CONFIRMED: actual ChapterArchiveStore deleted a sentinel outside Documents/downloads")
        do {
            _ = try APIConfiguration(baseURLString: "http://example.test").origin()
            fatalError("HTTP accepted unexpectedly")
        } catch APIError.invalidBaseURL {
            print("PASS: native API configuration rejects HTTP by default")
        }
        let request = APIRequest<EmptyAPIResponse>(path: ["sources", ".."])
        do {
            _ = try request.urlRequest(configuration: APIConfiguration(baseURLString: "https://example.test"))
            fatalError("Dot segment accepted unexpectedly")
        } catch APIError.invalidPath {
            print("PASS: native API request rejects dot path segments")
        }
    }
}
