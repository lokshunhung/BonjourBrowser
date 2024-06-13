//
//  NWParameters+Extensions.swift
//  BonjourBrowser
//
//  Created by Lok Shun Hung on 13/6/2024.
//

import Foundation
import Network

extension NWBrowser.Result {
    public var bonjour: Bonjour { .init(result: self) }
    public struct Bonjour {
        let result: NWBrowser.Result

        public var description: String {
            """
            endpoint: \(result.endpoint.debugDescription)
            interfaces: \(result.interfaces)
            metadata: \(result.metadata)
            """
        }
    }
}

extension NWBrowser.State {
    public var bonjour: Bonjour { .init(state: self) }
    public struct Bonjour {
        let state: NWBrowser.State

        public var description: String {
            return switch state {
            case .setup: ".setup"
            case .ready: ".ready"
            case .failed(let nwError): ".failed(\(nwError))"
            case .cancelled: ".cancelled"
            case .waiting(let nwError): ".waiting(\(nwError))"
            @unknown default: "@unknown"
            }
        }
    }
}

extension NWConnection.State {
    public var bonjour: Bonjour { .init(state: self) }
    public struct Bonjour {
        let state: NWConnection.State
        
        public var description: String {
            return switch state {
            case .setup: ".setup"
            case .waiting(let nwError): ".waiting(\(nwError))"
            case .preparing: ".preparing"
            case .ready: ".ready"
            case .failed(let nwError): ".failed(\(nwError))"
            case .cancelled: ".cancelled"
            @unknown default: "@unknown"
            }
        }
    }
}

extension NWListener.State {
    public var bonjour: Bonjour { .init(state: self) }
    public struct Bonjour {
        let state: NWListener.State

        public var description: String {
            return switch state {
            case .setup: ".setup"
            case .waiting(let nwError): ".waiting(\(nwError))"
            case .ready: ".ready"
            case .failed(let nwError): ".failed(\(nwError))"
            case .cancelled: ".cancelled"
            @unknown default: "@unknown"
            }
        }
    }
}

extension NWParameters {
    public enum bonjour {
        public static func tcp() -> NWParameters {
            let options = NWProtocolTCP.Options()
            options.enableKeepalive = true
            options.keepaliveIdle = 2

            let `self` = NWParameters(tls: nil, tcp: options)
            self.includePeerToPeer = true

            return self
        }
    }
}
