//
//  AppDelegateExtension.swift
//  Yggdrasil Network
//
//  Created by Neil Alexander on 11/01/2019.
//

import Foundation
import NetworkExtension
import Yggdrasil
import SwiftUI

#if os(iOS)
class PlatformAppDelegate: UIResponder, UIApplicationDelegate {}
typealias PlatformApplication = UIApplication
typealias ApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
#elseif os(macOS)
class PlatformAppDelegate: NSObject, NSApplicationDelegate {}
typealias PlatformApplication = NSApplication
typealias ApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
#endif

class CrossPlatformAppDelegate: PlatformAppDelegate, ObservableObject {
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()
    let yggdrasilComponent = "eu.neilalexander.yggdrasil.extension"
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            if let conn = notification.object as? NEVPNConnection {
                self.updateStatus(conn: conn)
            }
        })
        
        self.vpnTunnelProviderManagerInit()
        self.makeIPCRequests()
    }
    
    func toggleYggdrasil() {
        if !self.yggdrasilEnabled {
            print("Starting VPN tunnel")
            do {
                try self.vpnManager.connection.startVPNTunnel()
            } catch {
                print("Failed to start VPN tunnel: \(error.localizedDescription)")
                return
            }
            print("Started VPN tunnel")
        } else {
            print("Stopping VPN tunnel")
            self.vpnManager.connection.stopVPNTunnel()
            print("Stopped VPN tunnel")
        }
        self.yggdrasilEnabled = !self.yggdrasilEnabled
    }
    
    var yggdrasilConfig: ConfigurationProxy? = nil
    
    private var adminTimer: DispatchSourceTimer?
    
    @Published var yggdrasilEnabled: Bool = false
    @Published var yggdrasilConnected: Bool = false
    
    @Published var yggdrasilIP: String = "N/A"
    @Published var yggdrasilSubnet: String = "N/A"
    @Published var yggdrasilCoords: String = "[]"

    @Published var yggdrasilPeers: [[String: Any]] = [[:]]
    @Published var yggdrasilDHT: [[String: Any]] = [[:]]
    @Published var yggdrasilNodeInfo: [String: Any] = [:]
    
    func yggdrasilVersion() -> String {
        return Yggdrasil.MobileGetVersion()
    }
    
    func applicationDidBecomeActive(_ application: PlatformApplication) {
        print("Application became active")
        
        if self.adminTimer == nil {
            self.adminTimer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue(label: "Admin Queue"))
            self.adminTimer!.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(2), leeway: DispatchTimeInterval.seconds(1))
            self.adminTimer!.setEventHandler {
                self.makeIPCRequests()
            }
        }
        if self.adminTimer != nil {
            self.adminTimer!.resume()
        }
        
        self.updateStatus(conn: self.vpnManager.connection)
    }
    
    func updateStatus(conn: NEVPNConnection) {
        if conn.status == .connected {
            self.makeIPCRequests()
        } else if conn.status == .disconnecting || conn.status == .disconnected {
            self.clearStatus()
        }
        self.yggdrasilConnected = self.yggdrasilEnabled && self.yggdrasilPeers.count > 0 && self.yggdrasilDHT.count > 0
        print("Connection status: \(yggdrasilEnabled), \(yggdrasilConnected)")
    }
    
    func applicationWillResignActive(_ application: PlatformApplication) {
        if self.adminTimer != nil {
            self.adminTimer!.suspend()
        }
    }
    
    func vpnTunnelProviderManagerInit() {
        print("Loading saved managers...")
        
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            guard error == nil else {
                print("Failed to load VPN managers: \(error?.localizedDescription ?? "(no error)")")
                return
            }
            
            guard let savedManagers else {
                print("Expected to find saved managers but didn't")
                return
            }
            
            print("Found \(savedManagers.count) saved VPN managers")
            for manager in savedManagers {
                guard let proto = manager.protocolConfiguration as? NETunnelProviderProtocol else {
                    continue
                }
                guard let identifier = proto.providerBundleIdentifier else {
                    continue
                }
                guard identifier == self.yggdrasilComponent else {
                    continue
                }
                print("Found saved VPN Manager")
                self.vpnManager = manager
                break
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error: Error?) in
                if error == nil {
                    if let vpnConfig = self.vpnManager.protocolConfiguration as? NETunnelProviderProtocol,
                       let confJson = vpnConfig.providerConfiguration!["json"] as? Data {
                        if let loaded = try? ConfigurationProxy(json: confJson) {
                            print("Found existing protocol configuration")
                            self.yggdrasilConfig = loaded
                        } else {
                            print("Existing protocol configuration is invalid, ignoring")
                        }
                    }
                }
                
                if self.yggdrasilConfig == nil {
                    print("Generating new protocol configuration")
                    self.yggdrasilConfig = ConfigurationProxy()
                    
                    if let config = self.yggdrasilConfig {
                        try? config.save(to: &self.vpnManager)
                    }
                }
                
                self.vpnManager.localizedDescription = "Yggdrasil"
                self.vpnManager.isEnabled = true
            })
        }
    }
    
    func makeIPCRequests() {
        if self.vpnManager.connection.status != .connected {
            return
        }
        if let session = self.vpnManager.connection as? NETunnelProviderSession {
            try? session.sendProviderMessage("address".data(using: .utf8)!) { (address) in
                if let address = address {
                    self.yggdrasilIP = String(data: address, encoding: .utf8)!
                    NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("subnet".data(using: .utf8)!) { (subnet) in
                if let subnet = subnet {
                    self.yggdrasilSubnet = String(data: subnet, encoding: .utf8)!
                    NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("coords".data(using: .utf8)!) { (coords) in
                if let coords = coords {
                    self.yggdrasilCoords = String(data: coords, encoding: .utf8)!
                    NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("peers".data(using: .utf8)!) { (peers) in
                if let peers = peers {
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: peers, options: []) as? [[String: Any]] {
                        self.yggdrasilPeers = jsonResponse
                        NotificationCenter.default.post(name: .YggdrasilPeersUpdated, object: nil)
                    }
                }
            }
            try? session.sendProviderMessage("dht".data(using: .utf8)!) { (peers) in
                if let peers = peers {
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: peers, options: []) as? [[String: Any]] {
                        self.yggdrasilDHT = jsonResponse
                        NotificationCenter.default.post(name: .YggdrasilDHTUpdated, object: nil)
                    }
                }
            }
        }
    }
    
    func clearStatus() {
        self.yggdrasilIP = "N/A"
        self.yggdrasilSubnet = "N/A"
        self.yggdrasilCoords = "[]"
        self.yggdrasilPeers = []
        self.yggdrasilDHT = []
        NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
        NotificationCenter.default.post(name: .YggdrasilPeersUpdated, object: nil)
        NotificationCenter.default.post(name: .YggdrasilDHTUpdated, object: nil)
    }
}
