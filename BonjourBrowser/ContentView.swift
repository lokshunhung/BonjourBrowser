//
//  ContentView.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        BonjourView {
            BrowserView(viewModel: .init(service: .init()))
        } connectionView: {
            ConnectionView(viewModel: .init(service: .init()))
        } listenerView: {
            ListenerView(viewModel: .init(service: .init()))
        }
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
    }
}

#Preview {
    ContentView()
}
