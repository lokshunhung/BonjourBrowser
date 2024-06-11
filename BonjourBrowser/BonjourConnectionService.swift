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
    public typealias State = NWConnection.State
    public typealias Path = NWPath

    private var connection: NWConnection?
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
        let connection = queue.sync {
            if let connection = self.connection { return connection }
            let connection = NWConnection(
                to: result.endpoint,
                using: Info.Bonjour.nwParameters
            )
            self.connection = connection
            return connection
        }
        connection.stateUpdateHandler = { [weak self] in self?.onStateChanged($0) }
        connection.pathUpdateHandler = { [weak self] in self?.onPathUpdated($0) }
        connection.viabilityUpdateHandler = { [weak self] in self?.onViabilityUpdated($0) }
        connection.betterPathUpdateHandler = { [weak self] in self?.onBetterPathUpdated($0) }
        connection.start(queue: queue)
    }

    public func stop() {
        Logger.connection.info("stop")
        queue.sync {
            guard let connection else { return }
            connection.cancel()
            self.connection = nil
            self.state = .cancelled
            self.path = nil
            self.isViable = false
            self.hasBetterPath = false
        }
    }

    // MARK: NWConnection Handlers

    private func onStateChanged(_ state: NWConnection.State) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.connection.info("status \(String(describing: state))")
        self.state = state
    }

    private func onPathUpdated(_ newPath: NWPath) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.connection.info("path-> \(String(describing: newPath))")
        self.path = newPath
    }

    private func onViabilityUpdated(_ newIsViable: Bool) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.connection.info("viable \(newIsViable)")
        self.isViable = newIsViable
    }

    private func onBetterPathUpdated(_ newHasBetterPath: Bool) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.connection.info("better path \(newHasBetterPath)")
        self.hasBetterPath = newHasBetterPath
    }
}

private extension Logger {
    static let connection: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BonjourConnectionService"
    )
}
