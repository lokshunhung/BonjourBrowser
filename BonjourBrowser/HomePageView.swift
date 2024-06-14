//
//  HomePageView.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 14/6/2024.
//

import SwiftUI

public struct HomePageRoute: Route {}

public struct HomePageView: View {
    @ObservedObject var viewModel: Model

    public var body: some View {
        BonjourView {
            BrowserView(viewModel: viewModel.browserViewModel)
        } connectionView: {
            ConnectionView(viewModel: viewModel.connectionViewModel)
        } listenerView: {
            ListenerView(viewModel: viewModel.listenerViewModel)
        }
        .navigationTitle("Bonjour Browser")
    }

    @MainActor public final class Model: ObservableObject {
        public let browserViewModel: BrowserView.Model
        public let connectionViewModel: ConnectionView.Model
        public let listenerViewModel: ListenerView.Model

        public init(
            browserService: BonjourBrowserService,
            connectionService: BonjourConnectionService,
            listenerService: BonjourListenerService,
            mainQueue: DispatchQueue
        ) {
            self.browserViewModel = .init(service: browserService, mainQueue: mainQueue)
            self.connectionViewModel = .init(service: connectionService, mainQueue: mainQueue)
            self.listenerViewModel = .init(service: listenerService, mainQueue: mainQueue)

            browserViewModel.onResultSelected = { [weak connectionService] result in
                connectionService?.start(with: result)
            }
        }
    }
}
