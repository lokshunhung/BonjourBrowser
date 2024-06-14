//
//  App.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import SwiftUI

@main
struct BonjourBrowserApp: App {
    private let component: AppComponent = .init()

    var body: some Scene {
        WindowGroup {
            AppView(appModel: self.component.appModel) {
                self.component.home()
                    .modifier(self.component.navigationDestinationModifier)
            }
        }
    }
}

private struct AppView<Content: View>: View {
    @StateObject var appModel: AppModel
    let content: () -> Content

    var body: some View {
        NavigationStack(path: $appModel.path) {
            content()
        }
        .environmentObject(appModel)
    }
}

private final class AppComponent {
    private let mainQueue: DispatchQueue = .main
    private let userDefaults: UserDefaults = .standard

    private lazy var navigationPathStorage: AppModel.NavigationPathStorage =
        .live(self.userDefaults)

    private let browserService: BonjourBrowserService = .init()
    private let connectionService: BonjourConnectionService = .init()
    private let listenerService: BonjourListenerService = .init()

    lazy var appModel: AppModel =
        .init(pathStorage: self.navigationPathStorage)

    @MainActor private func viewModel(_ route: HomePageRoute) -> HomePageView.Model {
        return .init(
            browserService: self.browserService,
            connectionService: self.connectionService,
            listenerService: self.listenerService,
            mainQueue: self.mainQueue
        )
    }

    @MainActor private func viewModel(_ route: ConnectionDetailPageRoute) -> ConnectionDetailPageView.Model {
        return .init(
            connection: route.connection,
            mainQueue: self.mainQueue
        )
    }

    @MainActor func home() -> some View {
        HomePageView(viewModel: viewModel(HomePageRoute()))
    }

    var navigationDestinationModifier: some ViewModifier {
        NavigationDestinationModifier(component: self)
    }

    private struct NavigationDestinationModifier: ViewModifier {
        let component: AppComponent

        func body(content: Content) -> some View {
            Group {
                content
            }
            .navigationDestination(for: HomePageRoute.self) { route in
                HomePageView(viewModel: component.viewModel(route))
            }
            .navigationDestination(for: ConnectionDetailPageRoute.self) { route in
                ConnectionDetailPageView(viewModel: component.viewModel(route))
            }
        }
    }
}
