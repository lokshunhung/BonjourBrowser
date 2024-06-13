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

public class BonjourListenerService: ObservableObject {
    public typealias Connection = NWConnection
    public typealias Group = NWConnectionGroup
    public typealias State = NWListener.State

    private var listener: NWListener?
    private let queue: DispatchQueue = .init(
        label: "gnlok.BonjourBrowserApp.BonjourListenerService",
        target: .global(qos: .userInitiated)
    )

    @Published public private(set) var connections: [Connection] = []
    @Published public private(set) var groups: [Group] = []
    @Published public private(set) var state: State = .setup

    public init() {}

    deinit { stop() }

    public func start() throws {
        let listener = try queue.sync {
            if let listener = self.listener { return listener }
            let listener = try NWListener(using: .bonjour.tcp())
            self.listener = listener
            return listener
        }
        listener.newConnectionHandler = { [weak self] in self?.onNewConnection($0) }
//        listener.newConnectionGroupHandler = { [weak self] in self?.onNewConnectionGroup($0) }
        listener.stateUpdateHandler = { [weak self] in self?.onStateUpdated($0) }
        listener.serviceRegistrationUpdateHandler = { [weak self] in self?.onServiceRegistrationUpdated($0) }
        listener.service = NWListener.Service(name: nil, type: Info.bonjour.serviceType)
        listener.start(queue: queue)
    }

    public func stop() {
        queue.sync {
            guard let listener else { return }
            listener.cancel()
            self.listener = nil
            self.connections.forEach { $0.forceCancel() }
            self.groups.forEach { $0.cancel() }
            self.connections = []
            self.groups = []
            self.state = .cancelled
        }
    }

    private func onNewConnection(_ connection: NWConnection) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.listener.info("newcon \(String(describing: connection))")
        self.connections.append(connection)

        // TODO: set handlers + logs
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.connections.removeAll(where: { $0 === connection })
            case .setup, .waiting, .preparing, .ready: fallthrough
            @unknown default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func onNewConnectionGroup(_ group: NWConnectionGroup) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.listener.info("newgrp \(String(describing: group))")
        self.groups.append(group)
        group.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.groups.removeAll(where: { $0 === group })
            case .setup, .waiting, .ready: fallthrough
            @unknown default:
                break
            }
        }
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
