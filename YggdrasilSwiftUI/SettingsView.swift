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
    @State private var isResetting = false
    
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
            
            
             Section(content: {
                 VStack(alignment: .leading) {
                     Button("Reset configuration") {
                         self.isResetting.toggle()
                     }
                     .alert("Reset configuration", isPresented: $isResetting) {
                         Button("Confirm", action: resetConfig)
                         Button("Cancel", role: .cancel) { }
                     } message: {
                         Text("Are you sure you want to reset your configuration? This operation cannot be undone.")
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
                 }
             )
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
    
    func resetConfig() {
        self.appDelegate.yggdrasilConfig.reset()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
