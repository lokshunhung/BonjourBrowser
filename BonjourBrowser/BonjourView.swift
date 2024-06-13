//
//  BonjourView.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 12/6/2024.
//

import SwiftUI

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
                Text(String(describing: viewModel.state))
            }
            actionButtons()
        } header: {
            Text("Browser")
        }
        Section {
            ForEach(viewModel.results, id: \.[extension: .identifiable]) { result in
                Text(String(describing: result))
            }
        } header: {
            Text("Browser Results (\(viewModel.results.count))")
        }

    }

    private func actionButtons() -> some View {
        HStack {
            Button(role: .destructive, action: viewModel.send(.stopTapped)) {
                Text("Stop")
            }
            .buttonStyle(.bordered)
            Button(role: nil, action: viewModel.send(.startTapped)) {
                Text("Start")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }

    public final class Model: ObservableObject {
        private let service: BonjourBrowserService
        private let mainQueue: DispatchQueue

        @Published public private(set) var state: BonjourBrowserService.State?
        @Published public private(set) var results: [BonjourBrowserService.Result] = []

        public init(
            service: BonjourBrowserService,
            mainQueue: DispatchQueue = .main
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

        public func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
            { [weak self] in self?.reduce(action()) }
        }

        private func reduce(_ action: Action) {
            switch action {
            case .startTapped:
                service.start()
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

// MARK: - ConnectionView

public struct ConnectionView: View {
    @ObservedObject var viewModel: Model

    public var body: some View {
        Section {
            LabeledContent("State") {
                Text(String(describing: viewModel.state))
            }
            LabeledContent("Path") {
                Text(String(describing: viewModel.path))
            }
            actionButtons()
        } header: {
            Text("Connection")
        }
    }

    private func actionButtons() -> some View {
        EmptyView()
    }

    public final class Model: ObservableObject {
        private let service: BonjourConnectionService
        private let mainQueue: DispatchQueue

        @Published public private(set) var state: BonjourConnectionService.State?
        @Published public private(set) var path: BonjourConnectionService.Path?

        public init(
            service: BonjourConnectionService,
            mainQueue: DispatchQueue = .main
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

        public func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
            { [weak self] in self?.reduce(action()) }
        }

        private func reduce(_ action: Action) {
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
                Text(String(describing: viewModel.state))
            }
            actionButtons()
        } header: {
            Text("Listener")
        }
        Section {
            ForEach(viewModel.connection, id: \.[extension: .identifiable]) { connection in
                Text(String(describing: connection))
            }
        } header: {
            Text("Listener Connection (\(viewModel.connection.count))")
        }
    }

    private func actionButtons() -> some View {
        HStack {
            Button(role: .destructive, action: viewModel.send(.stopTapped)) {
                Text("Stop")
            }
            .buttonStyle(.bordered)
            Button(role: nil, action: viewModel.send(.startTapped)) {
                Text("Start")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }

    public final class Model: ObservableObject {
        private let service: BonjourListenerService
        private let mainQueue: DispatchQueue

        @Published public private(set) var connection: [BonjourListenerService.Connection] = []
        @Published public private(set) var group: [BonjourListenerService.Group] = []
        @Published public private(set) var state: BonjourListenerService.State?

        public init(
            service: BonjourListenerService,
            mainQueue: DispatchQueue = .main
        ) {
            self.service = service
            self.mainQueue = mainQueue

            service.$connection
                .receive(on: mainQueue)
                .assign(to: &$connection)
            service.$group
                .receive(on: mainQueue)
                .assign(to: &$group)
            service.$state.map(Optional.some)
                .receive(on: mainQueue)
                .assign(to: &$state)
        }

        public func send(_ action: @autoclosure @escaping () -> Action) -> () -> () {
            { [weak self] in self?.reduce(action()) }
        }

        private func reduce(_ action: Action) {
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

private extension BonjourBrowserService.Result {
    enum IdentifiableExtension { case identifiable }
    subscript(extension _: IdentifiableExtension) -> String { .init(describing: self) }
}

private extension BonjourListenerService.Connection {
    enum IdentifiableExtension { case identifiable }
    subscript(extension _: IdentifiableExtension) -> ObjectIdentifier { .init(self) }
}
