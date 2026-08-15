//
//  InternetConnectionStore.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import Foundation
import Network
import Observation

@Observable
final class InternetConnectionStore {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "WiderwillenInternetMonitor")

    private(set) var isConnected = true
    private(set) var connectionName = "Checking"

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            let connectionName = Self.connectionName(for: path)

            DispatchQueue.main.async {
                self?.isConnected = isConnected
                self?.connectionName = connectionName
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private static func connectionName(for path: NWPath) -> String {
        guard path.status == .satisfied else { return "Offline" }

        if path.usesInterfaceType(.wifi) {
            return "Wi-Fi"
        } else if path.usesInterfaceType(.cellular) {
            return "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        } else {
            return "Online"
        }
    }
}
