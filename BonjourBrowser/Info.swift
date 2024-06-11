//
//  Info.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 11/6/2024.
//

import Foundation
import Network

public enum Info {
    public enum Bonjour {
        public static let serviceType: String = "_scratchbonjourbrowser._tcp"
        public static let nwParameters: NWParameters = .tcp
    }
}
