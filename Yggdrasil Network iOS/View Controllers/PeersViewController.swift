//
//  PeersViewController.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 07/01/2019.
//

import UIKit
import NetworkExtension
import CoreTelephony

class PeersViewController: UITableViewController {
    var app = UIApplication.shared.delegate as! AppDelegate
    var config: [String: Any]? = nil
    
    @IBOutlet var peerTable: UITableView!
    @IBOutlet weak var addButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let proto = self.app.vpnManager.protocolConfiguration as? NETunnelProviderProtocol {
            config = proto.providerConfiguration ?? nil
        }
        
        self.navigationItem.rightBarButtonItems = [
            self.editButtonItem,
            self.addButtonItem
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilPeersUpdated), name: NSNotification.Name.YggdrasilPeersUpdated, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.YggdrasilPeersUpdated, object: nil)
    }
    
    @objc func onYggdrasilPeersUpdated(notification: NSNotification) {
        peerTable.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return app.yggdrasilSwitchPeers.count
        case 1:
            if let config = self.app.yggdrasilConfig {
                if let peers = config.get("Peers") as? [String] {
                    return peers.count
                }
            }
            return 0
        case 2:
            if UIDevice.current.hasCellularCapabilites {
                return 3
            }
            return 2
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "discoveredPeerPrototype", for: indexPath)
            let peers = app.yggdrasilSwitchPeers.sorted { (a, b) -> Bool in
                return (a["Port"] as! Int) < (b["Port"] as! Int)
            }
            
            if indexPath.row < peers.count {
                let value = peers[indexPath.row]
                let proto = value["Protocol"] as? String ?? "tcp"
                let sent = value["BytesSent"] as? Double ?? 0
                let recvd = value["BytesRecvd"] as? Double ?? 0
                let rx = self.format(bytes: sent)
                let tx = self.format(bytes: recvd)
                
                cell.textLabel?.text = "\(value["Endpoint"] ?? "unknown")"
                cell.detailTextLabel?.text = "\(proto.uppercased()) peer on port \(value["Port"] ?? "unknown"), sent \(tx), received \(rx)"
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "configuredPeerPrototype", for: indexPath)
            if let config = self.app.yggdrasilConfig {
                if let peers = config.get("Peers") as? [String] {
                    cell.textLabel?.text = peers[indexPath.last!]
                } else {
                    cell.textLabel?.text = "(unknown)"
                }
            }
            return cell
        case 2:
            switch indexPath.last {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "togglePrototype", for: indexPath) as! ToggleTableViewCell
                cell.isUserInteractionEnabled = true
                cell.label?.text = "Search for multicast peers"
                cell.label?.isEnabled = true
                cell.toggle?.addTarget(self, action: #selector(toggledMulticast), for: .valueChanged)
                cell.toggle?.isEnabled = true
                if let config = self.app.yggdrasilConfig {
                    let interfaces = config.get("MulticastInterfaces") as? [String] ?? []
                    cell.toggle?.isOn = interfaces.contains("en*")
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "togglePrototype", for: indexPath) as! ToggleTableViewCell
                cell.isUserInteractionEnabled = false
                cell.label?.text = "Search for nearby iOS peers"
                cell.label?.isEnabled = false
                cell.toggle?.addTarget(self, action: #selector(toggledAWDL), for: .valueChanged)
                cell.toggle?.setOn(false, animated: false)
                cell.toggle?.isEnabled = false
                /*if let config = self.app.yggdrasilConfig {
                    let interfaces = config.get("MulticastInterfaces") as? [String] ?? []
                    cell.toggle?.isOn = interfaces.contains("awdl0")
                }*/
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "menuPrototype", for: indexPath)
                cell.isUserInteractionEnabled = true
                cell.textLabel?.text = "Device settings"
                cell.textLabel?.isEnabled = true
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "menuPrototype", for: indexPath)
                cell.isUserInteractionEnabled = false
                cell.textLabel?.text = "Unknown"
                cell.textLabel?.isEnabled = true
                return cell
            }
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "configuredPeerPrototype", for: indexPath)
            cell.textLabel?.text = "(unknown)"
            return cell
        }
    }
    
    func format(bytes: Double) -> String {
        guard bytes > 0 else {
            return "0 bytes"
        }

        // Adapted from http://stackoverflow.com/a/18650828
        let suffixes = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        let k: Double = 1000
        let i = floor(log(bytes) / log(k))

        // Format number with thousands separator and everything below 1 GB with no decimal places.
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = i < 3 ? 0 : 1
        numberFormatter.numberStyle = .decimal

        let numberString = numberFormatter.string(from: NSNumber(value: bytes / pow(k, i))) ?? "Unknown"
        let suffix = suffixes[Int(i)]
        return "\(numberString) \(suffix)"
    }
    
    @objc func toggledMulticast(_ sender: UISwitch) {
        if let config = self.app.yggdrasilConfig {
            var interfaces = config.get("MulticastInterfaces") as! [String]
            if sender.isOn {
                interfaces.append("en*")
            } else {
                interfaces.removeAll(where: { $0 == "en*" })
            }
            config.set("MulticastInterfaces", to: interfaces as [String])
            try? config.save(to: &app.vpnManager)
        }
    }
    
    @objc func toggledAWDL(_ sender: UISwitch) {
        if let config = self.app.yggdrasilConfig {
            var interfaces = config.get("MulticastInterfaces") as! [String]
            if sender.isOn {
                interfaces.append("awdl0")
            } else {
                interfaces.removeAll(where: { $0 == "awdl0" })
            }
            config.set("MulticastInterfaces", to: interfaces as [String])
            try? config.save(to: &app.vpnManager)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            if self.app.yggdrasilPeers.count > 0 {
              return "Connected Peers"
            }
            return "No peers currently connected"
        case 1:
            if let config = self.app.yggdrasilConfig {
                if let peers = config.get("Peers") as? [String] {
                    if peers.count > 0 {
                        return "Configured Peers"
                    }
                }
            }
            return "No peers currently configured"
        case 2:
            return "Peer Connectivity"
        default: return "(Unknown)"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Yggdrasil will automatically attempt to connect to configured peers when started."
        case 2:
            var str = "Multicast peers will be discovered on the same Wi-Fi network or via USB."
            if UIDevice.current.hasCellularCapabilites {
                str += " Data charges may apply when using mobile data. You can prevent mobile data usage in the device settings."
            }
            return str
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.first == 1
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        switch indexPath.first {
        case 0:
            return [UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "Disconnect", handler: { (action, index) in
                
            })]
        case 1:
            return [UITableViewRowAction(style: UITableViewRowAction.Style.normal, title: "Remove", handler: { (action, index) in
                print(action, index)
                if let config = self.app.yggdrasilConfig {
                    config.remove(index: index.last!, from: "Peers")
                    do {
                        try config.save(to: &self.app.vpnManager)
                        tableView.reloadSections(IndexSet(integer: 1), with: UITableView.RowAnimation.automatic)
                    } catch {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.parent?.present(alert, animated: true, completion: nil)
                        print("Error removing: \(error)")
                    }
                }
            })]
        default:
            return []
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.first {
        case 2:
            if let last = indexPath.last, last == 2 {
                UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL, options: [:]) { (result) in
                    NSLog("Result " + result.description)
                }
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func addNewPeerButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add Configured Peer", message: """
            Enter the full URI of the peer to add. Yggdrasil will automatically connect to this peer when started.
        """, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Add", style: .default) { (alertAction) in
            let textField = alert.textFields![0] as UITextField
            if let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if let config = self.app.yggdrasilConfig {
                    if let peers = config.get("Peers") as? [String], !peers.contains(text) {
                        config.add(text, in: "Peers")
                        do {
                            try config.save(to: &self.app.vpnManager)
                            if let index = config.get("Peers") as? [String] {
                                self.peerTable.insertRows(at: [IndexPath(indexes: [1, index.count-1])], with: .automatic)
                                self.peerTable.reloadSections(IndexSet(integer: 1), with: UITableView.RowAnimation.automatic)
                            }
                        } catch {
                            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.parent?.present(alert, animated: true, completion: nil)
                            print("Add error: \(error)")
                        }
                    } else {
                        let alert = UIAlertController(title: "Error", message: "Peer already exists", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.parent?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField { (textField) in
            textField.placeholder = "tcp://hostname:port"
        }
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
}
