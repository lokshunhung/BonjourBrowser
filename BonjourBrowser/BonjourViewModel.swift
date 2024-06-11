//
//  BonjourViewModel.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import Combine
import Foundation
import Network

public final class BonjourViewModel: ObservableObject {
    private let browserService: BonjourBrowserService
    private let connectionService: BonjourConnectionService
    private let listenerService: BonjourListenerService

    @Published public private(set) var browserState: NWBrowser.State?
    @Published public private(set) var connectionState: NWConnection.State?
    @Published public private(set) var listenerState: NWListener.State?

    public init(
        browserService: BonjourBrowserService = .init(),
        connectionService: BonjourConnectionService = .init(),
        listenerService: BonjourListenerService = .init()
    ) {
        self.browserService = browserService
        self.connectionService = connectionService
        self.listenerService = listenerService

        browserService.$state.map(Optional.some).assign(to: &$browserState)
        connectionService.$state.map(Optional.some).assign(to: &$connectionState)
        listenerService.$state.map(Optional.some).assign(to: &$listenerState)
    }
}
