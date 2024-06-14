//
//  BonjourListenerService.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import Combine
import Foundation
import Network
import OSLog

/// Starts listening for incoming connections, and automatically accepts any incoming connections.
/// All connections managed share the same serial `DispatchQueue` provided internally in this class.
public final class BonjourListenerService: ObservableObject {
    public typealias Group = NWConnectionGroup
    public typealias State = NWListener.State

    private var listener: NWListener?
    private let queue: DispatchQueue = .init(
        label: "gnlok.BonjourBrowserApp.BonjourListenerService",
        target: .global(qos: .userInitiated)
    )

    @Published public private(set) var connections: [Connection] = []
    @Published public private(set) var state: State = .setup

    public init() {}

    deinit { self.stop() }

    public func start() throws {
        try self.queue.sync {
            guard self.listener == nil else { return }
            let listener = try NWListener(
                using: .bonjour.tcp(),
                on: NWEndpoint.Port.any
            )
            self.listener = listener
            self.bind(asDelegateTo: listener)
            listener.service = NWListener.Service(
                name: nil,
                type: Info.bonjour.serviceType
            )
            listener.start(queue: self.queue)
        }
    }

    public func stop() {
        self.queue.sync {
            guard let listener = self.listener else { return }
            listener.cancel()
            self.listener = nil
            self.connections.forEach { $0.forceCancel() }
            self.connections = []
            self.state = .cancelled
        }
    }

    public func remove(connection: Connection) {
        self.queue.sync {
            self.connections.removeAll(where: { $0 === connection })
        }
        connection.forceCancel()
    }

    // MARK: NWListener Handlers

    private func bind(asDelegateTo listener: NWListener) {
        listener.newConnectionHandler = { [weak self] in self?.onNewConnection($0) }
//        listener.newConnectionGroupHandler = { [weak self] in self?.onNewConnectionGroup($0) }
        listener.stateUpdateHandler = { [weak self] in self?.onStateUpdated($0) }
        listener.serviceRegistrationUpdateHandler = { [weak self] in self?.onServiceRegistrationUpdated($0) }
    }

    private func onNewConnection(_ connection: NWConnection) {
        dispatchPrecondition(condition: .onQueue(self.queue))
        Logger.listener.info("newcon \(String(describing: connection))")

        let connection = Connection(connection: connection, queue: self.queue)
        self.connections.append(connection)

        connection.start()
    }

    private func onStateUpdated(_ newState: NWListener.State) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.listener.info("status \(String(describing: newState))")
        self.state = newState
    }

    private func onServiceRegistrationUpdated(_ change: NWListener.ServiceRegistrationChange) {
        dispatchPrecondition(condition: .onQueue(queue))
        switch change {
        case .add(let endpoint):
            Logger.listener.info("registration + \(String(describing: endpoint))")
        case .remove(let endpoint):
            Logger.listener.info("registration - \(String(describing: endpoint))")
        @unknown default:
            Logger.listener.info("registration ??")
        }
    }
}

private extension Logger {
    static let listener: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BonjourListenerService"
    )
}
