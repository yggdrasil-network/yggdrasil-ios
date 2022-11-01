//
//  NSNotification.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 20/02/2019.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Notification.Name {
    static let YggdrasilSelfUpdated = Notification.Name("YggdrasilSelfUpdated")
    static let YggdrasilPeersUpdated = Notification.Name("YggdrasilPeersUpdated")
    static let YggdrasilSettingsUpdated = Notification.Name("YggdrasilSettingsUpdated")
    static let YggdrasilDHTUpdated = Notification.Name("YggdrasilPeersUpdated")
}
