//
//  BonjourView.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 12/6/2024.
//

import SwiftUI
import SwiftUINavigation

public struct BonjourView<
    BrowserView: View,
    ConnectionView: View,
    ListenerView: View
> : View {
    let browserView: () -> BrowserView
    let connectionView: () -> ConnectionView
    let listenerView: () -> ListenerView

    public var body: some View {
        List {
            browserView()
            connectionView()
            listenerView()
        }
    }
}

// MARK: - BrowserView

public struct BrowserView: View {
    @ObservedObject var viewModel: Model

    public var body: some View {
        Section {
            LabeledContent("State") {
                Text(viewModel.state?.bonjour.description ?? "nil")
            }
            actionButtons()
        } header: {
            Text("Browser")
        }
        Section {
            ForEach(viewModel.results.enumerated().map({ $0 }), id: \.offset) { offset, result in
                Button(action: send(.resultTapped(result: result))) {
                    HStack {
                        Text(String(offset)).foregroundStyle(.gray)
                        Text(result.bonjour.description).foregroundStyle(.foreground)
                    }
                }
            }
            .alert($viewModel.alert, action: send(Action.alert(action:)))
        } header: {
            Text("Browser Results (\(viewModel.results.count))")
        }
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handle(action: action()) }
    }

    private func send<T>(_ action: @escaping (T) -> Action) -> (T) -> () {
        { [weak viewModel] in viewModel?.handle(action: action($0)) }
    }

    private func actionButtons() -> some View {
        HStack {
            Button(role: .destructive, action: send(.stopTapped)) {
                Text("Stop")
            }
            .buttonStyle(.bordered)
            Button(role: nil, action: send(.startTapped)) {
                Text("Start")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor public final class Model: ObservableObject {
        private let service: BonjourBrowserService
        private let mainQueue: DispatchQueue

        @Published public private(set) var state: BonjourBrowserService.State?
        @Published public private(set) var results: [BonjourBrowserService.Result] = []
        @Published public internal(set) var alert: AlertState<AlertAction>? = nil

        public var onResultSelected: (_ result: BonjourBrowserService.Result) -> () = { _ in fatalError("\(\Model.onResultSelected)") }

        public init(
            service: BonjourBrowserService,
            mainQueue: DispatchQueue
        ) {
            self.service = service
            self.mainQueue = mainQueue

            service.$state.map(Optional.some)
                .receive(on: mainQueue)
                .assign(to: &self.$state)
            service.$browseResults.map(Array.init)
                .receive(on: mainQueue)
                .assign(to: &self.$results)
        }

        public func handle(action: Action) {
            switch action {
            case .startTapped:
                self.service.start()
            case .stopTapped:
                self.service.stop()
            case .resultTapped(let result):
                self.alert = .confirm(result: result)
            case .alert(let action):
                self.handleAlert(action: action)
            }
        }

        private func handleAlert(action: AlertAction?) {
            switch action {
            case .confirm(let result):
                self.onResultSelected(result)
            case nil:
                break
            }
        }
    }

    public enum Action {
        case startTapped
        case stopTapped
        case resultTapped(result: BonjourBrowserService.Result)
        case alert(action: AlertAction?)
    }

    public enum AlertAction {
        case confirm(result: BonjourBrowserService.Result)
    }
}

extension AlertState<BrowserView.AlertAction> {
    static func confirm(result: BonjourBrowserService.Result) -> Self {
        AlertState {
            TextState("Connect to Peer")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
            ButtonState(action: .confirm(result: result)) {
                TextState("Connect")
            }
        } message: {
            TextState(result.endpoint.debugDescription)
        }
    }
}

// MARK: - ConnectionView

public struct ConnectionView: View {
    @ObservedObject var viewModel: Model

    public var body: some View {
        Section {
            ForEach(viewModel.connections) { connection in
                ConnectionRowView(viewModel: ConnectionRowView.Model(connection, mainQueue: viewModel.mainQueue))
            }
        } header: {
            HStack {
                Text("Outgoing Connections (\(viewModel.connections.count))")
                Spacer()
                Button("Stop All", action: send(.stopAllTapped))
                    .buttonStyle(.borderless)
                    .font(.footnote)
            }
        }
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handle(action: action()) }
    }

    @MainActor public final class Model: ObservableObject {
        private let service: BonjourConnectionService
        let mainQueue: DispatchQueue

        @Published public private(set) var connections: [Connection] = []

        public init(
            service: BonjourConnectionService,
            mainQueue: DispatchQueue
        ) {
            self.service = service
            self.mainQueue = mainQueue

            service.$connections
                .receive(on: mainQueue)
                .map(\.values).map(Array.init)
                .assign(to: &self.$connections)
        }

        public func handle(action: Action) {
            switch action {
            case .stopAllTapped:
                self.service.stopAll()
            }
        }
    }

    public enum Action {
        case stopAllTapped
    }
}

// MARK: - ListenerView

public struct ListenerView: View {
    @ObservedObject var viewModel: Model

    public var body: some View {
        Section {
            LabeledContent("State") {
                Text(viewModel.state?.bonjour.description ?? "nil")
            }
            actionButtons()
        } header: {
            Text("Listener")
        }
        Section {
            ForEach(viewModel.connections) { connection in
                ConnectionRowView(viewModel: ConnectionRowView.Model(connection, mainQueue: viewModel.mainQueue))
            }
        } header: {
            Text("Listener Connections (\(viewModel.connections.count))")
        }
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handle(action: action()) }
    }

    private func actionButtons() -> some View {
        HStack {
            Button(role: .destructive, action: send(.stopTapped)) {
                Text("Stop")
            }
            .buttonStyle(.bordered)
            Button(role: nil, action: send(.startTapped)) {
                Text("Start")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor public final class Model: ObservableObject {
        private let service: BonjourListenerService
        let mainQueue: DispatchQueue

        @Published public private(set) var connections: [Connection] = []
        @Published public private(set) var state: BonjourListenerService.State?

        public init(
            service: BonjourListenerService,
            mainQueue: DispatchQueue
        ) {
            self.service = service
            self.mainQueue = mainQueue

            service.$connections
                .receive(on: mainQueue)
                .assign(to: &self.$connections)
            service.$state.map(Optional.some)
                .receive(on: mainQueue)
                .assign(to: &self.$state)
        }

        public func handle(action: Action) {
            switch action {
            case .startTapped:
                try? self.service.start()
            case .stopTapped:
                self.service.stop()
            }
        }
    }

    public enum Action {
        case startTapped
        case stopTapped
    }
}

public struct ConnectionRowView: View {
    @ObservedObject var viewModel: Model

    // TODO: NavigationLink(value:label:)
    public var body: some View {
        HStack {
            Text(viewModel.state)
                .foregroundStyle(.gray)
                .frame(width: 80)
            Text(viewModel.description)
        }
    }

    @MainActor public final class Model: ObservableObject {
        @Published public private(set) var state: String = ""
        @Published public private(set) var description: String = ""

        public init(_ connection: Connection, mainQueue: DispatchQueue) {
            connection.$state
                .receive(on: mainQueue)
                .map(\.bonjour.description)
                .map { description in
                    description.prefix(while: { $0 != "(" })
                }
                .map(String.init)
                .assign(to: &self.$state)
            connection.objectWillChange
                .delay(for: .milliseconds(10), scheduler: mainQueue)
                .receive(on: mainQueue)
                .prepend(())
                .map { _ in connection.debugDescription }
                .assign(to: &self.$description)
        }
    }
}
