//
//  YggdrasilSwiftUIApp.swift
//  YggdrasilSwiftUI
//
//  Created by Neil on 10/02/2023.
//

import SwiftUI
import NetworkExtension

@main
struct Application: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(CrossPlatformAppDelegate.self) static var appDelegate: CrossPlatformAppDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(CrossPlatformAppDelegate.self) static var appDelegate: CrossPlatformAppDelegate
    #endif
    
    @State private var selection: String? = "Status"
    @State private var config: ConfigurationProxy = ConfigurationProxy()

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(selection: $selection) {
                    NavigationLink(destination: StatusView(yggdrasilConfiguration: $config)) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 24)
                            Text("Status")
                        }
                    }
                    NavigationLink(destination: PeersView()) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 24)
                            Text("Peers")
                        }
                    }
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 24)
                            Text("Settings")
                        }
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(200)
            } detail: {
                StatusView(yggdrasilConfiguration: $config)
            }
            .navigationTitle("Yggdrasil")
            .navigationSplitViewStyle(.automatic)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
