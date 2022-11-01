import NetworkExtension
import Foundation
import Yggdrasil

class PacketTunnelProvider: NEPacketTunnelProvider {

    var yggdrasil: MobileYggdrasil = MobileYggdrasil()
    var conduit: DummyConduitEndpoint? = nil
    var yggdrasilConfig: ConfigurationProxy?
    
    @objc func readPacketsFromTun() {
        autoreleasepool {
            self.packetFlow.readPackets { (packets: [Data], protocols: [NSNumber]) in
                for packet in packets {
                    try? self.yggdrasil.sendBuffer(packet, length: packet.count)
                }
                self.readPacketsFromTun()
            }
        }
    }

    @objc func writePacketsToTun() {
        while true {
            autoreleasepool {
                if let data = try? self.yggdrasil.recv() {
                    self.packetFlow.writePackets([data], withProtocols: [NSNumber](repeating: AF_INET6 as NSNumber, count: 1))
                }
            }
        }
    }
    
    func startYggdrasil() -> Error? {
        var err: Error? = nil

        self.setTunnelNetworkSettings(nil) { (error: Error?) -> Void in
            NSLog("Starting Yggdrasil")
            
            if let error = error {
                NSLog("Failed to clear Yggdrasil tunnel network settings: " + error.localizedDescription)
                err = error
            }
            if self.yggdrasilConfig == nil {
                NSLog("No configuration proxy!")
                return
            }
            if let config = self.yggdrasilConfig {
                NSLog("Configuration loaded")
                
                do {
                    self.conduit = try self.yggdrasil.startJSON(config.data())
                } catch {
                    NSLog("Starting Yggdrasil process produced an error: " + error.localizedDescription)
                    return
                }

                let address = self.yggdrasil.getAddressString()
                let subnet = self.yggdrasil.getSubnetString()
                
                NSLog("Yggdrasil IPv6 address: " + address)
                NSLog("Yggdrasil IPv6 subnet: " + subnet)
                
                let tunnelNetworkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: address)
                tunnelNetworkSettings.ipv6Settings = NEIPv6Settings(addresses: [address], networkPrefixLengths: [7])
                tunnelNetworkSettings.ipv6Settings?.includedRoutes = [NEIPv6Route(destinationAddress: "0200::", networkPrefixLength: 7)]

                NSLog("Setting tunnel network settings...")
                
                self.setTunnelNetworkSettings(tunnelNetworkSettings) { (error: Error?) -> Void in
                    NSLog("setTunnelNetworkSettings completed successfully")
                    if let error = error {
                        NSLog("Failed to set Yggdrasil tunnel network settings: " + error.localizedDescription)
                        err = error
                    } else {
                        NSLog("Yggdrasil tunnel settings set successfully")
                        
                        let readthread: Thread = Thread(target: self, selector: #selector(self.readPacketsFromTun), object: nil)
                        readthread.name = "TUN Packet Reader"
                        readthread.qualityOfService = .utility
                        
                        let writethread: Thread = Thread(target: self, selector: #selector(self.writePacketsToTun), object: nil)
                        writethread.name = "TUN Packet Writer"
                        writethread.qualityOfService = .utility
                        
                        readthread.start()
                        writethread.start()
                    }
                }
            }
        }
        return err
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if let conf = (self.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration {
            if let json = conf["json"] as? Data {
                do {
                    self.yggdrasilConfig = try ConfigurationProxy(json: json)
                } catch {
                    NSLog("Error in Yggdrasil startTunnel: Configuration is invalid")
                    return
                }
                if let error = self.startYggdrasil() {
                    NSLog("Error in Yggdrasil startTunnel: " + error.localizedDescription)
                } else {
                    NSLog("Yggdrasil completion handler called")
                    completionHandler(nil)
                }
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        try? self.yggdrasil.stop()
        super.stopTunnel(with: reason, completionHandler: completionHandler)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        let request = String(data: messageData, encoding: .utf8)
        switch request {
        case "address":
            completionHandler?(self.yggdrasil.getAddressString().data(using: .utf8))
        case "subnet":
            completionHandler?(self.yggdrasil.getSubnetString().data(using: .utf8))
        case "coords":
            completionHandler?(self.yggdrasil.getCoordsString().data(using: .utf8))
        case "peers":
            completionHandler?(self.yggdrasil.getPeersJSON().data(using: .utf8))
        case "switchpeers":
            completionHandler?(self.yggdrasil.getSwitchPeersJSON().data(using: .utf8))
        default:
            completionHandler?(nil)
        }
    }
}
