//
//  App.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import SwiftUI

@main
struct BonjourBrowserApp: App {
    let appModel: AppModel
    let homePageViewModel: HomePageView.Model

    init() {
        let component = AppComponent()

        self.appModel = component.appModel
        self.homePageViewModel = component.homePageViewModel
    }

    var body: some Scene {
        WindowGroup {
            AppView(appModel: appModel) {
            } homePage: {
                HomePageView(viewModel: homePageViewModel)
            }
        }
    }
}

private struct AppView: View {
    @StateObject var appModel: AppModel
    let trail: () -> ()
    let homePage: () -> HomePageView

    var body: some View {
        NavigationStack(path: $appModel.path) {
            homePage()
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

    @MainActor
    lazy var homePageViewModel: HomePageView.Model =
        .init(
            browserService: self.browserService,
            connectionService: self.connectionService,
            listenerService: self.listenerService,
            mainQueue: self.mainQueue
        )
}
