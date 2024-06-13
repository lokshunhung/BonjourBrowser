//
//  Connection.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 13/6/2024.
//

import Combine
import Foundation
import Network
import OSLog

public final class Connection: ObservableObject, @unchecked Sendable {
    public typealias State = NWConnection.State
    public typealias Path = NWPath

    private let connection: NWConnection
    private let queue: DispatchQueue

    @Published public private(set) var state: State = .setup
    @Published public private(set) var path: Path? = nil
    @Published public private(set) var isViable: Bool = false
    @Published public private(set) var hasBetterPath: Bool = false

    public init(
        connection: NWConnection,
        queue: DispatchQueue
    ) {
        self.connection = connection
        self.queue = queue

        connection.stateUpdateHandler = { [weak self] in self?.onStateChanged($0) }
        connection.pathUpdateHandler = { [weak self] in self?.onPathUpdated($0) }
        connection.viabilityUpdateHandler = { [weak self] in self?.onViabilityUpdated($0) }
        connection.betterPathUpdateHandler = { [weak self] in self?.onBetterPathUpdated($0) }
    }

    public func start() {
        connection.start(queue: queue)
    }

    public func cancel() {
        connection.cancel()
    }

    public func cancelCurrentEndpoint() {
        connection.cancelCurrentEndpoint()
    }

    public func forceCancel() {
        connection.forceCancel()
    }

    // MARK: NWConnection Handlers

    private func onStateChanged(_ state: NWConnection.State) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.peer.info("status \(String(describing: state))")
        self.state = state
    }

    private func onPathUpdated(_ newPath: NWPath) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.peer.info("path-> \(String(describing: newPath))")
        self.path = newPath
    }

    private func onViabilityUpdated(_ newIsViable: Bool) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.peer.info("viable \(newIsViable)")
        self.isViable = newIsViable
    }

    private func onBetterPathUpdated(_ newHasBetterPath: Bool) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.peer.info("better path \(newHasBetterPath)")
        self.hasBetterPath = newHasBetterPath
    }
}

extension Connection {
    public var terminated: () {
        get async {
            for await state in self.$state.values {
                switch state {
                case .setup, .waiting, .preparing, .ready:
                    continue
                case .failed, .cancelled: fallthrough
                @unknown default:
                    return
                }
            }
        }
    }
}

extension Connection: Identifiable {
    public var id: ObjectIdentifier {
        ObjectIdentifier(self.connection)
    }
}

extension Connection: CustomDebugStringConvertible {
    public var debugDescription: String {
        self.connection.debugDescription
    }
}

private extension Logger {
    static let peer: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Connection"
    )
}
