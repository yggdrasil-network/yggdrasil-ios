//
//  IPCResponses.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 20/02/2019.
//

import Foundation
import SwiftUI

struct YggdrasilSummary: Codable {
    var address: String
    var subnet: String
    var publicKey: String
    var enabled: Bool
    var peers: [YggdrasilPeer]
    
    func list() -> [String] {
        return peers.map { $0.remote }
    }
    
    func listUp() -> [String] {
        return peers.filter { $0.up }.map { $0.remote }
    }
}

struct YggdrasilPeer: Codable, Identifiable {
    var id: String { remote } // For Identifiable protocol
    let remote: String
    let up: Bool
    let address: String?
    let key: String?
    let priority: UInt8
    let cost: UInt16?
    
    enum CodingKeys: String, CodingKey {
        case remote = "URI"
        case up = "Up"
        case address = "IP"
        case key = "Key"
        case priority = "Priority"
        case cost = "Cost"
    }
    
    public func getStatusBadgeColor() -> SwiftUI.Color {
        if self.up {
            return .green
        }
        return .gray
    }
}
