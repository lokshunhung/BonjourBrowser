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

/// Reactive wrapper around `NWConnection`.
/// Instances of this class are single-use, and should be disposed when connection terminates.
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

        connection.stateUpdateHandler = { [weak self] in self?.onStateUpdated($0) }
        connection.pathUpdateHandler = { [weak self] in self?.onPathUpdated($0) }
        connection.viabilityUpdateHandler = { [weak self] in self?.onViabilityUpdated($0) }
        connection.betterPathUpdateHandler = { [weak self] in self?.onBetterPathUpdated($0) }
    }

    public func start() {
        self.connection.start(queue: self.queue)
    }

    public func cancel() {
        self.connection.cancel()
    }

    public func cancelCurrentEndpoint() {
        self.connection.cancelCurrentEndpoint()
    }

    public func forceCancel() {
        self.connection.forceCancel()
    }

    // MARK: NWConnection Handlers

    private func onStateUpdated(_ state: NWConnection.State) {
        dispatchPrecondition(condition: .onQueue(self.queue))
        Logger.peer.info("status \(String(describing: state))")
        self.state = state
    }

    private func onPathUpdated(_ newPath: NWPath) {
        dispatchPrecondition(condition: .onQueue(self.queue))
        Logger.peer.info("path-> \(String(describing: newPath))")
        self.path = newPath
    }

    private func onViabilityUpdated(_ newIsViable: Bool) {
        dispatchPrecondition(condition: .onQueue(self.queue))
        Logger.peer.info("viable \(newIsViable)")
        self.isViable = newIsViable
    }

    private func onBetterPathUpdated(_ newHasBetterPath: Bool) {
        dispatchPrecondition(condition: .onQueue(self.queue))
        Logger.peer.info("better path \(newHasBetterPath)")
        self.hasBetterPath = newHasBetterPath
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

extension Connection: Equatable {
    public static func == (lhs: Connection, rhs: Connection) -> Bool {
        lhs === rhs
    }
}

extension Connection: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

private extension Logger {
    static let peer: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Connection"
    )
}
