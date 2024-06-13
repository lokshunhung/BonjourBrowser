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
            .alert($viewModel.alert, action: send(Action.handleAlertAction))
        } header: {
            Text("Browser Results (\(viewModel.results.count))")
        }
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handleAction(action()) }
    }

    private func send<T>(_ action: @escaping (T) -> Action) -> (T) -> () {
        { [weak viewModel] in viewModel?.handleAction(action($0)) }
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
                .assign(to: &$state)
            service.$browseResults.map(Array.init)
                .receive(on: mainQueue)
                .assign(to: &$results)
        }

        public func handleAction(_ action: Action) {
            switch action {
            case .startTapped:
                service.start()
            case .stopTapped:
                service.stop()
            case .resultTapped(let result):
                alert = .confirmResult(result)
            case .handleAlertAction(let action):
                handleAlertAction(action)
            }
        }

        private func handleAlertAction(_ action: AlertAction?) {
            switch action {
            case .confirm(let result):
                onResultSelected(result)
            case nil:
                break
            }
        }
    }

    public enum Action {
        case startTapped
        case stopTapped
        case resultTapped(result: BonjourBrowserService.Result)
        case handleAlertAction(AlertAction?)
    }

    public enum AlertAction {
        case confirm(result: BonjourBrowserService.Result)
    }
}

extension AlertState<BrowserView.AlertAction> {
    static func confirmResult(_ result: BonjourBrowserService.Result) -> Self {
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
            LabeledContent("State") {
                Text(viewModel.state?.bonjour.description ?? "nil")
            }
            LabeledContent("Path") {
                Text(viewModel.path?.debugDescription ?? "nil")
            }
            actionButtons()
        } header: {
            Text("Connection")
        }
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handleAction(action()) }
    }

    private func actionButtons() -> some View {
        HStack {
            Button(role: .destructive, action: send(.stopTapped)) {
                Text("Stop")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.state == .setup || viewModel.state == .cancelled)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor public final class Model: ObservableObject {
        private let service: BonjourConnectionService
        private let mainQueue: DispatchQueue

        @Published public private(set) var state: BonjourConnectionService.State?
        @Published public private(set) var path: BonjourConnectionService.Path?

        public init(
            service: BonjourConnectionService,
            mainQueue: DispatchQueue
        ) {
            self.service = service
            self.mainQueue = mainQueue

            service.$state.map(Optional.some)
                .receive(on: mainQueue)
                .assign(to: &$state)
            service.$path
                .receive(on: mainQueue)
                .assign(to: &$path)
        }

        public func handleAction(_ action: Action) {
            switch action {
            case .startTapped(let browserResult):
                service.start(using: browserResult)
            case .stopTapped:
                service.stop()
            }
        }
    }

    public enum Action {
        case startTapped(browserResult: BonjourBrowserService.Result)
        case stopTapped
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
            ForEach(viewModel.connections, id: \.[extension: .identifiable]) { connection in
                Text(connection.debugDescription)
            }
        } header: {
            Text("Listener Connections (\(viewModel.connections.count))")
        }
    }

    private func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
        { [weak viewModel] in viewModel?.handleAction(action()) }
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
        private let mainQueue: DispatchQueue

        @Published public private(set) var connections: [BonjourListenerService.Connection] = []
        @Published public private(set) var groups: [BonjourListenerService.Group] = []
        @Published public private(set) var state: BonjourListenerService.State?

        public init(
            service: BonjourListenerService,
            mainQueue: DispatchQueue
        ) {
            self.service = service
            self.mainQueue = mainQueue

            service.$connections
                .receive(on: mainQueue)
                .assign(to: &$connections)
            service.$groups
                .receive(on: mainQueue)
                .assign(to: &$groups)
            service.$state.map(Optional.some)
                .receive(on: mainQueue)
                .assign(to: &$state)
        }

        public func handleAction(_ action: Action) {
            switch action {
            case .startTapped:
                try? service.start()
            case .stopTapped:
                service.stop()
            }
        }
    }

    public enum Action {
        case startTapped
        case stopTapped
    }
}

// MARK: - NSObject Identifiable

private extension BonjourListenerService.Connection {
    enum IdentifiableExtension { case identifiable }
    subscript(extension _: IdentifiableExtension) -> ObjectIdentifier { .init(self) }
}
