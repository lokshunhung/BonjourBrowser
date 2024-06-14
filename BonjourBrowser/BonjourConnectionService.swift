//
//  BonjourConnectionService.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import Combine
import Foundation
import Network
import OSLog

/// Manages all outgoing `NWConnection` initiated through `start(with:)`.
/// All connections managed share the same serial `DispatchQueue` provided internally in this class.
///
/// To start a connection to a discovered service, provide a `NWBrowser.Result`,
/// which could be obtained with `BonjourBrowserService`.
public final class BonjourConnectionService: ObservableObject {
    public typealias State = Connection.State
    public typealias Path = Connection.Path

    private let queue: DispatchQueue = .init(
        label: "gnlok.BonjourBrowser.BonjourConnectionService",
        target: .global(qos: .userInitiated)
    )

    @Published public private(set) var connections: [NWBrowser.Result: [Connection]] = [:]

    public init() {}

    deinit { self.stopAll() }

    @discardableResult
    public func start(with result: NWBrowser.Result) -> Connection {
        Logger.connection.info("start(with:) \(String(describing: result))")
        return self.queue.sync {
            if let connection = self.connections[result]?.last,
               !connection.state.isTerminated {
                Logger.connection.warning("start(with:) - unexpected call while a non-terminated connection with same result: \(String(describing: result))")
                return connection
            }

            let networkConnection = NWConnection(
                to: result.endpoint,
                using: .bonjour.tcp()
            )
            let connection = Connection(
                connection: networkConnection,
                queue: self.queue
            )
            self.connections[result, default: []].append(connection)
            connection.start()
            return connection
        }
    }

    public func stopAll() {
        Logger.connection.info("stopAll")
        let connections = self.queue.sync {
            let connections = self.connections
            self.connections = [:]
            return connections
        }
        for connection in connections.values.flatMap({ $0 }) {
            connection.forceCancel()
        }
    }
}

private extension Connection.State {
    var isTerminated: Bool {
        return switch self {
        case .setup, .waiting, .preparing, .ready: false
        case .failed, .cancelled: true
        @unknown default: true
        }
    }
}

private extension Logger {
    static let connection: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BonjourConnectionService"
    )
}
