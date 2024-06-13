//
//  AppModel.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 12/6/2024.
//

import Combine
import Foundation
import SwiftUI

public final class AppModel: ObservableObject {
    @Published public var path: NavigationPath = .init()
}
