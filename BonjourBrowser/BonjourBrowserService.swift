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

    public var canStop: Bool { self.browser != nil }

    public init() {}

    deinit { self.stop() }

    public func start() {
        Logger.browser.info("start")
        self.queue.sync {
            guard self.browser == nil else { return }
            let browser = NWBrowser(
                for: .bonjour(type: Info.bonjour.serviceType, domain: nil),
                using: .bonjour.tcp()
            )
            self.browser = browser
            self.bind(asDelegateTo: browser)
            browser.start(queue: self.queue)
        }
    }

    public func stop() {
        Logger.browser.info("stop")
        queue.sync {
            guard let browser = self.browser else { return }
            browser.cancel()
            self.browser = nil
            self.state = .cancelled
        }
    }

    // MARK: NWBrowser Handlers

    private func bind(asDelegateTo browser: NWBrowser) {
        browser.stateUpdateHandler = { [weak self] in self?.onStateUpdate($0) }
        browser.browseResultsChangedHandler = { [weak self] in self?.onBrowserResultsChanged($0, $1) }
    }

    private func onStateUpdate(_ newState: NWBrowser.State) {
        dispatchPrecondition(condition: .onQueue(self.queue))
        Logger.browser.info("status \(String(describing: newState))")
        self.state = newState
    }

    private func onBrowserResultsChanged(_ newResults: Set<NWBrowser.Result>, _ changes: Set<NWBrowser.Result.Change>) {
        dispatchPrecondition(condition: .onQueue(self.queue))
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
