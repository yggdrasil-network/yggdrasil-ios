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
    var yggdrasilConfig: ConfigurationProxy
    let yggdrasilComponent = "eu.neilalexander.yggdrasil.extension"
    private var adminTimer: DispatchSourceTimer?
    
    override init() {
        self.yggdrasilConfig = ConfigurationProxy(manager: self.vpnManager)
        super.init()
        
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            if let conn = notification.object as? NEVPNConnection {
                switch conn.status {
                case .connected:
                    self.requestSummaryIPC()
                case .disconnecting, .disconnected:
                    self.clearStatus()
                default:
                    break
                }
            }
        })
        
        self.vpnTunnelProviderManagerInit()
    }
    
    @Published var yggdrasilEnabled: Bool = false {
        didSet {
            if yggdrasilEnabled {
                if vpnManager.connection.status != .connected && vpnManager.connection.status != .connecting {
                    do {
                        try self.vpnManager.connection.startVPNTunnel()
                    } catch {
                        print("Failed to start VPN tunnel: \(error.localizedDescription)")
                        return
                    }
                }
            } else {
                if vpnManager.connection.status != .disconnected && vpnManager.connection.status != .disconnecting {
                    self.vpnManager.connection.stopVPNTunnel()
                }
            }
        }
    }
    
    @Published var yggdrasilSupported: Bool = true
    @Published var yggdrasilConnected: Bool = false
    
    @Published var yggdrasilPublicKey: String = "N/A"
    @Published var yggdrasilIP: String = "N/A"
    @Published var yggdrasilSubnet: String = "N/A"
    @Published var yggdrasilCoords: String = "[]"
    
    @Published var yggdrasilPeers: [YggdrasilPeer] = []
    
    func yggdrasilVersion() -> String {
        return Yggdrasil.MobileGetVersion()
    }
    
    func becameActive() {
        print("Application became active")
        
        if self.adminTimer == nil {
            self.adminTimer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
            self.adminTimer!.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(2), leeway: DispatchTimeInterval.seconds(1))
            self.adminTimer!.setEventHandler {
                self.updateStatus(conn: self.vpnManager.connection)
            }
        }
        if self.adminTimer != nil {
            self.adminTimer!.resume()
        }
        
        self.requestSummaryIPC()
        self.updateStatus(conn: self.vpnManager.connection)
    }
    
    func becameInactive() {
        print("Application became inactive")
        
        if self.adminTimer != nil {
            self.adminTimer!.suspend()
        }
    }
    
    func becameBackground() {}
    
    func updateStatus(conn: NEVPNConnection) {
        if conn.status == .connected || conn.status == .connecting {
            self.yggdrasilEnabled = true
            self.requestSummaryIPC()
        } else if conn.status == .disconnecting || conn.status == .disconnected {
            self.yggdrasilEnabled = false
            self.clearStatus()
        }
    }
    
    func vpnTunnelProviderManagerInit() {
        print("Loading saved managers...")
        
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            guard error == nil else {
                print("Failed to load VPN managers: \(error?.localizedDescription ?? "(no error)")")
                self.yggdrasilSupported = false
                return
            }
            
            guard let savedManagers else {
                print("Expected to find saved managers but didn't")
                // self.yggdrasilSupported = false
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
                var loadedConfig = false
                if error == nil {
                    if let vpnConfig = self.vpnManager.protocolConfiguration as? NETunnelProviderProtocol,
                       let confJson = vpnConfig.providerConfiguration!["json"] as? Data {
                        if let loaded = try? ConfigurationProxy(json: confJson, manager: self.vpnManager) {
                            print("Found existing protocol configuration")
                            self.yggdrasilConfig = loaded
                            loadedConfig = true
                        } else {
                            print("Existing protocol configuration is invalid, ignoring")
                        }
                    }
                }
                
                if !loadedConfig {
                    print("Generating new protocol configuration")
                    self.yggdrasilConfig = ConfigurationProxy(manager: self.vpnManager)
                    try? self.yggdrasilConfig.save(to: &self.vpnManager)
                }
                
                self.vpnManager.localizedDescription = "Yggdrasil"
                self.vpnManager.isEnabled = true
            })
        }
    }
    
    func requestSummaryIPC() {
        if self.vpnManager.connection.status != .connected {
            return
        }
        if let session = self.vpnManager.connection as? NETunnelProviderSession {
            try? session.sendProviderMessage("summary".data(using: .utf8)!) { js in
                if let js = js, let summary = try? JSONDecoder().decode(YggdrasilSummary.self, from: js) {
                    self.yggdrasilEnabled = summary.enabled
                    self.yggdrasilIP = summary.address
                    self.yggdrasilSubnet = summary.subnet
                    self.yggdrasilPublicKey = summary.publicKey
                    self.yggdrasilPeers = summary.peers
                    self.yggdrasilConnected = summary.peers.filter { $0.up }.count > 0
                }
            }
        }
    }
    
    func clearStatus() {
        self.yggdrasilConnected = false
        self.yggdrasilIP = "N/A"
        self.yggdrasilSubnet = "N/A"
        self.yggdrasilCoords = "[]"
        self.yggdrasilPeers = []
    }
}
