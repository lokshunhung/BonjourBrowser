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

/// Given a `NWBrowser.Result`, initiates a connection to the discovered service.
/// The `NWBrowser.Result` could be obtained with `BonjourBrowserService`.
public final class BonjourConnectionService: ObservableObject {
    public typealias State = Connection.State
    public typealias Path = Connection.Path

    private var connection: Connection?
    private let queue: DispatchQueue = .init(
        label: "gnlok.BonjourBrowser.BonjourConnectionService",
        target: .global(qos: .userInitiated)
    )

    @Published public private(set) var state: State = .setup
    @Published public private(set) var path: Path? = nil
    @Published public private(set) var isViable: Bool = false
    @Published public private(set) var hasBetterPath: Bool = false

    public init() {}

    deinit { stop() }

    public func start(using result: NWBrowser.Result) {
        Logger.connection.info("start")
        queue.sync {
            guard self.connection == nil else { return }
            let networkConnection = NWConnection(
                to: result.endpoint,
                using: .bonjour.tcp()
            )
            let connection = Connection(
                connection: networkConnection,
                queue: queue
            )
            self.connection = connection
            self.bind(connection)
            connection.start()
        }
    }

    public func stop() {
        Logger.connection.info("stop")
        queue.sync {
            guard let connection = self.connection else { return }
            connection.forceCancel()
            self.connection = nil
            self.state = .cancelled
            self.path = nil
            self.isViable = false
            self.hasBetterPath = false
        }
    }

    private func bind(_ connection: Connection) {
        connection.$state
            .receive(on: queue)
            .assign(to: &self.$state)
        connection.$path
            .receive(on: queue)
            .assign(to: &self.$path)
        connection.$isViable
            .receive(on: queue)
            .assign(to: &self.$isViable)
        connection.$hasBetterPath
            .receive(on: queue)
            .assign(to: &self.$hasBetterPath)
    }
}

private extension Logger {
    static let connection: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BonjourConnectionService"
    )
}
