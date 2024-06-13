//
//  BonjourBrowserService.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import Combine
import Foundation
import Network
import OSLog

/// Starts browsing available services with bonjour.
/// The obtained service can be connected using `BonjourConnectionService`.
public final class BonjourBrowserService: ObservableObject {
    public typealias State = NWBrowser.State
    public typealias Result = NWBrowser.Result

    private var browser: NWBrowser?
    private let queue: DispatchQueue = .init(
        label: "gnlok.BonjourBrowser.BonjourBrowserService",
        target: .global(qos: .userInitiated)
    )

    @Published public private(set) var state: State = .setup
    @Published public private(set) var browseResults: Set<Result> = []

    public init() {}

    deinit { stop() }

    public func start() {
        Logger.browser.info("start")
        let browser = queue.sync {
            if let browser = self.browser { return browser }
            let browser = NWBrowser(
                for: .bonjour(type: Info.bonjour.serviceType, domain: "local."),
                using: .bonjour.tcp()
            )
            self.browser = browser
            return browser
        }
        browser.stateUpdateHandler = { [weak self] in self?.onStateUpdate($0) }
        browser.browseResultsChangedHandler = { [weak self] in self?.onBrowserResultsChanged($0, $1) }
        browser.start(queue: queue)
    }

    public func stop() {
        Logger.browser.info("stop")
        queue.sync {
            guard let browser else { return }
            browser.cancel()
            self.browser = nil
            self.state = .cancelled
        }
    }

    // MARK: NWBrowser Handlers

    private func onStateUpdate(_ newState: NWBrowser.State) {
        dispatchPrecondition(condition: .onQueue(queue))
        Logger.browser.info("status \(String(describing: newState))")
        self.state = newState
    }

    private func onBrowserResultsChanged(_ newResults: Set<NWBrowser.Result>, _ changes: Set<NWBrowser.Result.Change>) {
        dispatchPrecondition(condition: .onQueue(queue))
        for change in changes {
            switch change {
            case .added(let result):
                Logger.browser.info("result + \(String(describing: result))")
            case .removed(let result):
                Logger.browser.info("result - \(String(describing: result))")
            case .changed(let old, let new, flags: _):
                Logger.browser.info("result ± \(old.endpoint.debugDescription) \(new.endpoint.debugDescription)")
            case .identical: fallthrough
            @unknown default:
                Logger.browser.info("result ??")
            }
        }
        self.browseResults = newResults
    }
}

private extension Logger {
    static let browser: Self = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BonjourBrowserService"
    )
}
