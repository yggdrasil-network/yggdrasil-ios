//
//  SettingsTableViewController.swift
//  YggdrasilNetwork
//
//  Created by Neil Alexander on 03/01/2019.
//

import UIKit
import NetworkExtension

class SettingsViewController: UITableViewController, UIDocumentBrowserViewControllerDelegate {
    var app = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var deviceNameField: UITextField!
    
    @IBOutlet weak var encryptionPublicKeyLabel: UILabel!
    @IBOutlet weak var signingPublicKeyLabel: UILabel!
    
    @IBOutlet weak var autoStartWiFiCell: UITableViewCell!
    @IBOutlet weak var autoStartMobileCell: UITableViewCell!
    
    @IBOutlet weak var sessionFirewallPeeredCell: UITableViewCell!
    @IBOutlet weak var sessionFirewallOtherCell: UITableViewCell!
    @IBOutlet weak var sessionFirewallOutboundCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let config = self.app.yggdrasilConfig {
            deviceNameField.text = config.get("name", inSection: "NodeInfo") as? String ?? ""
            encryptionPublicKeyLabel.text = config.get("EncryptionPublicKey") as? String ?? "Unknown"
            signingPublicKeyLabel.text = config.get("SigningPublicKey") as? String ?? "Unknown"
            
            sessionFirewallPeeredCell.accessoryType = config.get("AllowFromDirect", inSection: "SessionFirewall") as? Bool ?? true ? .checkmark : .none
            sessionFirewallOtherCell.accessoryType = config.get("AllowFromRemote", inSection: "SessionFirewall") as? Bool ?? true ? .checkmark : .none
            sessionFirewallOutboundCell.accessoryType = config.get("AlwaysAllowOutbound", inSection: "SessionFirewall") as? Bool ?? true ? .checkmark : .none
            
            autoStartWiFiCell.accessoryType = config.get("WiFi", inSection: "AutoStart") as? Bool ?? false ? .checkmark : .none
            autoStartMobileCell.accessoryType = config.get("Mobile", inSection: "AutoStart") as? Bool ?? false ? .checkmark : .none
        }
    }

    @IBAction func deviceNameEdited(_ sender: UITextField) {
        if let config = self.app.yggdrasilConfig {
            config.set("name", inSection: "NodeInfo", to: sender.text)
            try? config.save(to: &app.vpnManager)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.first {
        case 1:
            let settings = [
                "WiFi",
                "Mobile"
            ]
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = cell.accessoryType == .checkmark ? .none : .checkmark
                if let config = self.app.yggdrasilConfig {
                    config.set(settings[indexPath.last!], inSection: "AutoStart", to: cell.accessoryType == .checkmark)
                    try? config.save(to: &app.vpnManager)
                }
            }
        case 2:
            let settings = [
                "AllowFromDirect",
                "AllowFromRemote",
                "AlwaysAllowOutbound"
            ]
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = cell.accessoryType == .checkmark ? .none : .checkmark
                if let config = self.app.yggdrasilConfig {
                    config.set(settings[indexPath.last!], inSection: "SessionFirewall", to: cell.accessoryType == .checkmark)
                    try? config.save(to: &app.vpnManager)
                }
            }
        case 4:
            switch indexPath.last {
            case 0: // import
                if #available(iOS 11.0, *) {
                    let open = UIDocumentBrowserViewController(forOpeningFilesWithContentTypes: ["eu.neilalexander.yggdrasil.configuration"])
                    open.delegate = self
                    open.allowsDocumentCreation = false
                    open.allowsPickingMultipleItems = false
                    open.additionalTrailingNavigationBarButtonItems = [ UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelDocumentBrowser)) ]
                    self.present(open, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Import Configuration", message: "Not supported on this version of iOS!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            case 1: // export
                if let config = self.app.yggdrasilConfig, let data = config.data() {
                    var fileURL: URL?
                    var fileDir: URL?
                    do {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let date = dateFormatter.string(from: Date())
                        fileDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        fileURL = fileDir?.appendingPathComponent("Yggdrasil Backup \(date).yggconf")
                        try? data.write(to: fileURL!)
                    } catch {
                        break
                    }
                    if let dir = fileDir {
                        let sharedurl = dir.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
                        let furl: URL = URL(string: sharedurl)!
                        UIApplication.shared.open(furl, options: [:], completionHandler: nil)
                    }
                }
            default:
                break
            }
        case 5:
            let alert = UIAlertController(title: "Warning", message: "This operation will reset your configuration and generate new keys. This is not reversible unless your configuration has been exported. Changes will not take effect until the next time Yggdrasil is restarted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { action in
                self.app.yggdrasilConfig = ConfigurationProxy()
                if let config = self.app.yggdrasilConfig {
                    try? config.save(to: &self.app.vpnManager)
                    self.viewDidLoad()
                }}))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func cancelDocumentBrowser() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 11.0, *)
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        do {
            if let url = documentURLs.first {
                let data = try Data(contentsOf: url)
                let conf = try ConfigurationProxy(json: data)
                try conf.save(to: &self.app.vpnManager)
                self.app.yggdrasilConfig = conf
                
                controller.dismiss(animated: true, completion: nil)
                let alert = UIAlertController(title: "Import Configuration", message: "Configuration file has been imported.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } catch {
            controller.dismiss(animated: true, completion: nil)
            let alert = UIAlertController(title: "Import Failed", message: "Unable to import this configuration file.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        self.viewDidLoad()
    }
    
}
