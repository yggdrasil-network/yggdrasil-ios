//
//  SettingsView.swift
//  YggdrasilSwiftUI
//
//  Created by Neil on 10/02/2023.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var appDelegate = Application.appDelegate
    
    @State private var deviceName = ""
    
    var body: some View {
        Form {
            Section(content: {
                TextField("Device Name", text: $appDelegate.yggdrasilConfig.deviceName)
            }, header: {
                Text("Public Identity")
            })
            
            Section(content: {
                Toggle("Any network connection", isOn: $appDelegate.yggdrasilConfig.autoStartAny)
                Toggle("Wi-Fi networks", isOn: $appDelegate.yggdrasilConfig.autoStartWiFi)
#if os(macOS)
                Toggle("Ethernet networks", isOn: $appDelegate.yggdrasilConfig.autoStartEthernet)
#endif
#if os(iOS)
                Toggle("Mobile data", isOn: $appDelegate.yggdrasilConfig.autoStartMobile)
#endif
            }, header: {
                Text("Automatically start when connected to")
            })
            
            /*
             Section(content: {
             VStack(alignment: .leading) {
             Button("Import configuration") {
             
             }
             #if os(macOS)
             .buttonStyle(.link)
             #endif
             .foregroundColor(.accentColor)
             Text("Import configuration from another device, including the public key and Yggdrasil IP address.")
             .font(.system(size: 11))
             .foregroundColor(.gray)
             }
             
             VStack(alignment: .leading) {
             Button("Export configuration") {
             
             }
             #if os(macOS)
             .buttonStyle(.link)
             #endif
             .foregroundColor(.accentColor)
             Text("Configuration will be exported as a file. Your configuration contains your private key which is extremely sensitive. Do not share it with anyone.")
             .font(.system(size: 11))
             .foregroundColor(.gray)
             }
             
             VStack(alignment: .leading) {
             Button("Reset configuration") {
             
             }
             #if os(macOS)
             .buttonStyle(.link)
             #endif
             .foregroundColor(.red)
             Text("Resetting will overwrite with newly generated configuration. Your public key and Yggdrasil IP address will change.")
             .font(.system(size: 11))
             .foregroundColor(.gray)
             }
             }, header: {
             Text("Configuration")
             })
             */
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
