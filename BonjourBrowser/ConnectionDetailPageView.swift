//
//  ConnectionDetailPageView.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 14/6/2024.
//

import Combine
import SwiftUI

public struct ConnectionDetailPageRoute: Route {
    public let connection: Connection
    public init(connection: Connection) {
        self.connection = connection
    }
}

public struct ConnectionDetailPageView: View {
    @ObservedObject var viewModel: Model

    public var body: some View {
        Form {
            Section {
                LabeledContent("State") {
                    Text(viewModel.state.bonjour.description)
                }
                LabeledContent("Path") {
                    if let path = viewModel.path {
                        Text(String(describing: path))
                    } else {
                        Text("nil")
                    }
                }
                LabeledContent("Is Viable") {
                    Text(String(viewModel.isViable))
                }
                LabeledContent("Has Better Path") {
                    Text(String(viewModel.hasBetterPath))
                }
            } header: {
                Text("Info")
            }
            Section {
                Button("Stop", action: send(.stop))
            }
        }
        .navigationTitle("Connection Details")
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handle(action: action()) }
    }

    @MainActor public final class Model: ObservableObject {
        private let connection: Connection

        @Published public private(set) var state: Connection.State = .setup
        @Published public private(set) var path: Connection.Path? = nil
        @Published public private(set) var isViable: Bool = false
        @Published public private(set) var hasBetterPath: Bool = false

        public init(connection: Connection, mainQueue: DispatchQueue) {
            self.connection = connection

            connection.$state
                .receive(on: mainQueue)
                .assign(to: &self.$state)
            connection.$path
                .receive(on: mainQueue)
                .assign(to: &self.$path)
            connection.$isViable
                .receive(on: mainQueue)
                .assign(to: &self.$isViable)
            connection.$hasBetterPath
                .receive(on: mainQueue)
                .assign(to: &self.$hasBetterPath)
        }

        public func handle(action: Action) {
            switch action {
            case .stop:
                self.connection.forceCancel()
            }
        }
    }

    public enum Action {
        case stop
    }
}
