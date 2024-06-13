//
//  ContentView.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import SwiftUI

struct ContentView: View {
    @State var browserViewModel: BrowserView.Model
    @State var connectionViewModel: ConnectionView.Model
    @State var listenerViewModel: ListenerView.Model

    @MainActor init(
        browserService: BonjourBrowserService = .init(),
        connectionService: BonjourConnectionService = .init(),
        listenerService: BonjourListenerService = .init(),
        mainQueue: DispatchQueue = .main
    ) {
        self.browserViewModel = .init(service: browserService, mainQueue: mainQueue)
        self.connectionViewModel = .init(service: connectionService, mainQueue: mainQueue)
        self.listenerViewModel = .init(service: listenerService, mainQueue: mainQueue)

        browserViewModel.onResultSelected = { result in
            connectionService.start(using: result)
        }
    }

    var body: some View {
        BonjourView {
            BrowserView(viewModel: browserViewModel)
        } connectionView: {
            ConnectionView(viewModel: connectionViewModel)
        } listenerView: {
            ListenerView(viewModel: listenerViewModel)
        }
    }
}

#Preview {
    ContentView()
}
