//
//  AppDelegateExtension.swift
//  Yggdrasil Network
//
//  Created by Neil Alexander on 11/01/2019.
//

import Foundation
import NetworkExtension
import Yggdrasil
import UIKit

class CrossPlatformAppDelegate: PlatformAppDelegate {
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()

    #if os(iOS)
    let yggdrasilComponent = "eu.neilalexander.yggdrasil.extension"
    #elseif os(OSX)
    let yggdrasilComponent = "eu.neilalexander.yggdrasilmac.extension"
    #endif
    
    var yggdrasilConfig: ConfigurationProxy? = nil
    
    var yggdrasilAdminTimer: DispatchSourceTimer?
    
    var yggdrasilSelfIP: String = "N/A"
    var yggdrasilSelfSubnet: String = "N/A"
    var yggdrasilSelfCoords: String = "[]"

    var yggdrasilPeers: [[String: Any]] = [[:]]
    var yggdrasilSwitchPeers: [[String: Any]] = [[:]]
    var yggdrasilNodeInfo: [String: Any] = [:]
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if self.yggdrasilAdminTimer == nil {
            self.yggdrasilAdminTimer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue(label: "Admin Queue"))
            self.yggdrasilAdminTimer!.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(2), leeway: DispatchTimeInterval.seconds(1))
            self.yggdrasilAdminTimer!.setEventHandler {
                self.makeIPCRequests()
            }
        }
        if self.yggdrasilAdminTimer != nil {
            self.yggdrasilAdminTimer!.resume()
        }
        
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            if let conn = notification.object as? NEVPNConnection {
                self.updateStatus(conn: conn)
            }
        })
        
        self.updateStatus(conn: self.vpnManager.connection)
    }
    
    func updateStatus(conn: NEVPNConnection) {
        if conn.status == .connected {
            self.makeIPCRequests()
        } else if conn.status == .disconnecting || conn.status == .disconnected {
            self.clearStatus()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if self.yggdrasilAdminTimer != nil {
            self.yggdrasilAdminTimer!.suspend()
        }
    }
    
    func vpnTunnelProviderManagerInit() {
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                print(error)
            }
            
            if let savedManagers = savedManagers {
                for manager in savedManagers {
                    if (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.yggdrasilComponent {
                        print("Found saved VPN Manager")
                        self.vpnManager = manager
                    }
                }
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error: Error?) in
                if let error = error {
                    print(error)
                }
                
                if let vpnConfig = self.vpnManager.protocolConfiguration as? NETunnelProviderProtocol,
                    let confJson = vpnConfig.providerConfiguration!["json"] as? Data {
                    print("Found existing protocol configuration")
                    self.yggdrasilConfig = try? ConfigurationProxy(json: confJson)
                } else  {
                    print("Generating new protocol configuration")
                    self.yggdrasilConfig = ConfigurationProxy()
                }
                
                self.vpnManager.localizedDescription = "Yggdrasil"
                self.vpnManager.isEnabled = true
                
                
                if let config = self.yggdrasilConfig {
                    try? config.save(to: &self.vpnManager)
                }
            })
        }
    }
    
    func makeIPCRequests() {
        if self.vpnManager.connection.status != .connected {
            return
        }
        if let session = self.vpnManager.connection as? NETunnelProviderSession {
            try? session.sendProviderMessage("address".data(using: .utf8)!) { (address) in
                self.yggdrasilSelfIP = String(data: address!, encoding: .utf8)!
                NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
            }
            try? session.sendProviderMessage("subnet".data(using: .utf8)!) { (subnet) in
                self.yggdrasilSelfSubnet = String(data: subnet!, encoding: .utf8)!
                NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
            }
            try? session.sendProviderMessage("coords".data(using: .utf8)!) { (coords) in
                self.yggdrasilSelfCoords = String(data: coords!, encoding: .utf8)!
                NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
            }
            try? session.sendProviderMessage("peers".data(using: .utf8)!) { (peers) in
                if let jsonResponse = try? JSONSerialization.jsonObject(with: peers!, options: []) as? [[String: Any]] {
                    self.yggdrasilPeers = jsonResponse
                    NotificationCenter.default.post(name: .YggdrasilPeersUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("switchpeers".data(using: .utf8)!) { (switchpeers) in
                if let jsonResponse = try? JSONSerialization.jsonObject(with: switchpeers!, options: []) as? [[String: Any]] {
                    self.yggdrasilSwitchPeers = jsonResponse
                    NotificationCenter.default.post(name: .YggdrasilSwitchPeersUpdated, object: nil)
                }
            }
        }
    }
    
    func clearStatus() {
        self.yggdrasilSelfIP = "N/A"
        self.yggdrasilSelfSubnet = "N/A"
        self.yggdrasilSelfCoords = "[]"
        self.yggdrasilPeers = []
        self.yggdrasilSwitchPeers = []
        NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
        NotificationCenter.default.post(name: .YggdrasilPeersUpdated, object: nil)
        NotificationCenter.default.post(name: .YggdrasilSwitchPeersUpdated, object: nil)
    }
}
