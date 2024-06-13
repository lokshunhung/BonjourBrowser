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
    private let pathStorage: NavigationPathStorage
    private var cancellables: Set<AnyCancellable> = []

    @Published public var path: NavigationPath

    public init(pathStorage: NavigationPathStorage = .live(.standard)) {
        self.pathStorage = pathStorage
        self.path = pathStorage.read()

        self.$path
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [pathStorage] path in
                pathStorage.write(path)
            }
            .store(in: &self.cancellables)
    }

    public struct NavigationPathStorage {
        public var read: () -> NavigationPath
        public var write: (_ path: NavigationPath) -> ()

        public init(
            read: @escaping () -> NavigationPath,
            write: @escaping (_ path: NavigationPath) -> ()
        ) {
            self.read = read
            self.write = write
        }
    }
}

extension AppModel.NavigationPathStorage {
    private static let key = "gnlok.BonjourBrowser.AppModel.path"

    public static func live(_ userDefaults: UserDefaults = .standard) -> Self {
        .init(
            read: { () in
                if let data = userDefaults.data(forKey: Self.key),
                   let codable = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: data) {
                    return NavigationPath(codable)
                }
                return NavigationPath()
            },
            write: { path in
                if let codable = path.codable,
                   let data = try? JSONEncoder().encode(codable) {
                    userDefaults.set(data, forKey: Self.key)
                }
            }
        )
    }
}
