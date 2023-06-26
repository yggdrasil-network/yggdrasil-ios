//
//  IPCResponses.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 20/02/2019.
//

import Foundation

struct YggdrasilSummary: Codable {
    var address: String
    var subnet: String
    var publicKey: String
}

struct YggdrasilStatus: Codable {
    var enabled: Bool
    var coords: String
    var peers: Data
    var dht: Data
}
