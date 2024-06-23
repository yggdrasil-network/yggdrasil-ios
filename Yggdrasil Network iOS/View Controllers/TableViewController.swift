import UIKit
import NetworkExtension
import Yggdrasil

class TableViewController: UITableViewController {
    var app = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var connectedStatusLabel: UILabel!
    
    @IBOutlet var toggleTableView: UITableView!
    @IBOutlet var toggleLabel: UILabel!
    @IBOutlet var toggleConnect: UISwitch!
    
    @IBOutlet weak var statsSelfIPCell: UITableViewCell!
    @IBOutlet weak var statsSelfSubnetCell: UITableViewCell!
    
    @IBOutlet var statsSelfIP: UILabel!
    @IBOutlet var statsSelfSubnet: UILabel!
    @IBOutlet var statsSelfPeers: UILabel!
    
    @IBOutlet var statsVersion: UILabel!
    
    override func viewDidLoad() {      
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilSelfUpdated), name: NSNotification.Name.YggdrasilSelfUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilPeersUpdated), name: NSNotification.Name.YggdrasilPeersUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilSettingsUpdated), name: NSNotification.Name.YggdrasilSettingsUpdated, object: nil)
    }
    
    @IBAction func onRefreshButton(_ sender: UIButton) {
        sender.isEnabled = false
        app.makeIPCRequests()
        sender.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //NotificationCenter.default.addObserver(self, selector: #selector(TableViewController.VPNStatusDidChange(_:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        
        if let row = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: row, animated: true)
        }
        
        self.statsVersion.text = Yggdrasil.MobileGetVersion()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.onYggdrasilSelfUpdated(notification: NSNotification.init(name: NSNotification.Name.YggdrasilSettingsUpdated, object: nil))
    }
    
    override func viewWillLayoutSubviews() {
        self.onYggdrasilSelfUpdated(notification: NSNotification.init(name: NSNotification.Name.YggdrasilSettingsUpdated, object: nil))
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let row = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: row, animated: true)
        }
    }
    
    @objc func onYggdrasilSettingsUpdated(notification: NSNotification) {
        toggleLabel.isEnabled = !app.vpnManager.isOnDemandEnabled
        toggleConnect.isEnabled = !app.vpnManager.isOnDemandEnabled
        
        if let footer = toggleTableView.footerView(forSection: 0) {
            if let label = footer.textLabel {
                label.text = app.vpnManager.isOnDemandEnabled ? "Yggdrasil is configured to automatically start and stop based on available connectivity." : "Yggdrasil is configured to start and stop manually."
            }
        }
    }
    
    func updateConnectedStatus() {
        if self.app.vpnManager.connection.status == .connected {
            if app.yggdrasilPeers.count > 0 {
                connectedStatusLabel.text = "Enabled"
                connectedStatusLabel.textColor = UIColor(red: 0.37, green: 0.79, blue: 0.35, alpha: 1.0)
            } else {
                connectedStatusLabel.text = "No connectivity"
                connectedStatusLabel.textColor = UIColor.red
            }
        } else {
            connectedStatusLabel.text = "Not enabled"
            connectedStatusLabel.textColor = UIColor.systemGray
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func onYggdrasilSelfUpdated(notification: NSNotification) {
        statsSelfIP.text = app.yggdrasilSelfIP
        statsSelfSubnet.text = app.yggdrasilSelfSubnet
        
        statsSelfIPCell.layoutSubviews()
        statsSelfSubnetCell.layoutSubviews()
        
        let status = self.app.vpnManager.connection.status
        toggleConnect.isOn = status == .connecting || status == .connected
        
        self.updateConnectedStatus()
    }
    
    @objc func onYggdrasilDHTUpdated(notification: NSNotification) {
        self.updateConnectedStatus()
    }
    
    @objc func onYggdrasilPeersUpdated(notification: NSNotification) {
        let peercount = app.yggdrasilPeers.filter { $0["Up"] as? Bool ?? false }.count
        if peercount <= 0 {
            statsSelfPeers.text = "No peers"
        } else if peercount == 1 {
            statsSelfPeers.text = "\(peercount) peer"
        } else {
            statsSelfPeers.text = "\(peercount) peers"
        }
    }

    @IBAction func toggleVPNStatus(_ sender: UISwitch, forEvent event: UIEvent) {
        if sender.isOn {
            do {
                try self.app.vpnManager.connection.startVPNTunnel()
            } catch {
                print(error)
            }
        } else {
            self.app.vpnManager.connection.stopVPNTunnel()
        }
    }
}
