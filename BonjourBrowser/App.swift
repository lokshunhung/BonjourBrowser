//
//  App.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import SwiftUI

@main
struct BonjourBrowserApp: App {
    @StateObject var appModel: AppModel = .init()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appModel.path) {
                ContentView()
            }
            .environmentObject(appModel)
        }
    }
}
