import Combine
import Foundation
import Network

@MainActor
final class DownloadNetworkMonitor: ObservableObject {
    enum Connection: Equatable { case offline, cellular, wifi, other }

    @Published private(set) var connection: Connection = .other
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.keihatsu.download-network")

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            let value: Connection
            if path.status != .satisfied { value = .offline }
            else if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) { value = .wifi }
            else if path.usesInterfaceType(.cellular) { value = .cellular }
            else { value = .other }
            Task { @MainActor [weak self] in self?.connection = value }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
