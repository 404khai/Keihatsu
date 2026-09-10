import Foundation

nonisolated enum BackgroundDownloadEvent: Sendable {
    case progress(taskIdentifier: Int, written: Int64, expected: Int64)
    case completed(taskIdentifier: Int, location: URL, response: URLResponse?)
    case paused(taskIdentifier: Int, resumeData: Data?)
    case failed(taskIdentifier: Int, message: String)
}

/// Owns the lifecycle-bound background URLSession. The delegate moves Apple's
/// temporary file synchronously before returning, then hands an owned URL to
/// the download coordinator.
nonisolated final class BackgroundDownloadSession: @unchecked Sendable {
    typealias EventHandler = @Sendable (BackgroundDownloadEvent) -> Void

    private let identifier: String
    private let delegate: BackgroundDownloadDelegate
    private let session: URLSession

    init(identifier: String, incomingRoot: URL, usesBackgroundConfiguration: Bool = true) {
        self.identifier = identifier
        let configuration: URLSessionConfiguration
        if usesBackgroundConfiguration {
            configuration = .background(withIdentifier: identifier)
            configuration.sessionSendsLaunchEvents = true
            configuration.isDiscretionary = false
        } else {
            configuration = .ephemeral
        }
        configuration.httpMaximumConnectionsPerHost = 2
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 60 * 30
        let delegate = BackgroundDownloadDelegate(identifier: identifier, incomingRoot: incomingRoot)
        self.delegate = delegate
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        try? FileManager.default.createDirectory(at: incomingRoot, withIntermediateDirectories: true)
    }

    func setEventHandler(_ handler: EventHandler?) {
        delegate.setEventHandler(handler)
    }

    @discardableResult
    func start(request: URLRequest, description: String, resumeData: Data? = nil) -> Int {
        let task = resumeData.map(session.downloadTask(withResumeData:)) ?? session.downloadTask(with: request)
        task.taskDescription = description
        task.resume()
        return task.taskIdentifier
    }

    func taskDescriptions() async -> [Int: String] {
        await withCheckedContinuation { continuation in
            session.getAllTasks { tasks in
                continuation.resume(returning: Dictionary(uniqueKeysWithValues: tasks.compactMap { task in
                    task.taskDescription.map { (task.taskIdentifier, $0) }
                }))
            }
        }
    }

    func pause(taskIdentifier: Int) {
        session.getAllTasks { [weak self] tasks in
            guard let self, let task = tasks.first(where: { $0.taskIdentifier == taskIdentifier }) as? URLSessionDownloadTask else { return }
            task.cancel { [weak self] data in self?.delegate.notifyPaused(taskIdentifier: taskIdentifier, resumeData: data) }
        }
    }

    func cancel(taskIdentifier: Int) {
        session.getAllTasks { tasks in tasks.first(where: { $0.taskIdentifier == taskIdentifier })?.cancel() }
    }

    func cancelAll() {
        session.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
    }

}

nonisolated private final class BackgroundDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let identifier: String
    private let incomingRoot: URL
    private let lock = NSLock()
    private var eventHandler: BackgroundDownloadSession.EventHandler?
    private var completedTasks = Set<Int>()

    init(identifier: String, incomingRoot: URL) {
        self.identifier = identifier
        self.incomingRoot = incomingRoot
    }

    func setEventHandler(_ handler: BackgroundDownloadSession.EventHandler?) {
        lock.withLock { eventHandler = handler }
    }

    func notifyPaused(taskIdentifier: Int, resumeData: Data?) {
        emit(.paused(taskIdentifier: taskIdentifier, resumeData: resumeData))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        emit(.progress(taskIdentifier: downloadTask.taskIdentifier, written: totalBytesWritten, expected: totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let destination = incomingRoot.appending(path: "\(UUID().uuidString).download", directoryHint: .notDirectory)
            try FileManager.default.moveItem(at: location, to: destination)
            lock.withLock { _ = completedTasks.insert(downloadTask.taskIdentifier) }
            emit(.completed(taskIdentifier: downloadTask.taskIdentifier, location: destination, response: downloadTask.response))
        } catch {
            emit(.failed(taskIdentifier: downloadTask.taskIdentifier, message: error.localizedDescription))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let completed = lock.withLock { completedTasks.remove(task.taskIdentifier) != nil }
        guard !completed, let error = error as? URLError, error.code != .cancelled else { return }
        emit(.failed(taskIdentifier: task.taskIdentifier, message: error.localizedDescription))
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        BackgroundSessionCompletionRegistry.shared.finish(identifier: identifier)
    }

    private func emit(_ event: BackgroundDownloadEvent) {
        let handler = lock.withLock { eventHandler }
        handler?(event)
    }
}

nonisolated final class BackgroundSessionCompletionRegistry: @unchecked Sendable {
    static let shared = BackgroundSessionCompletionRegistry()
    private let lock = NSLock()
    private var handlers: [String: @Sendable () -> Void] = [:]

    private init() {}

    func register(identifier: String, completion: @escaping @Sendable () -> Void) {
        lock.withLock { handlers[identifier] = completion }
    }

    func finish(identifier: String) {
        let handler = lock.withLock { handlers.removeValue(forKey: identifier) }
        guard let handler else { return }
        DispatchQueue.main.async(execute: handler)
    }
}

private extension NSLock {
    nonisolated func withLock<T>(_ operation: () -> T) -> T {
        lock()
        defer { unlock() }
        return operation()
    }
}
