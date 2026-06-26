import Foundation
import Network
import Combine

final class HanaNetworkMonitor: ObservableObject {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "HanaNetworkMonitor")

    @Published private(set) var isExpensive = false
    @Published private(set) var usesCellular = false
    @Published private(set) var status: NWPath.Status = .requiresConnection

    var shouldTreatAsMetered: Bool {
        isExpensive || usesCellular
    }

    var statusTitle: String {
        switch status {
        case .satisfied:
            "已连接"
        case .unsatisfied:
            "未连接"
        case .requiresConnection:
            "需要连接"
        @unknown default:
            "未知"
        }
    }

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = path.status
                self?.isExpensive = path.isExpensive
                self?.usesCellular = path.usesInterfaceType(.cellular)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
