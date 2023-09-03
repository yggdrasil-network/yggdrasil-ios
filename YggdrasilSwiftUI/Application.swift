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
    @State private var selection: String? = "Status"
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(CrossPlatformAppDelegate.self) static var appDelegate: CrossPlatformAppDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(CrossPlatformAppDelegate.self) static var appDelegate: CrossPlatformAppDelegate
    #endif
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                ZStack {
                    List(selection: $selection) {
                        NavigationLink(destination: StatusView()) {
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
                    //.listStyle(.sidebar)
                    //.navigationSplitViewColumnWidth(200)
                    
                    Image("YggdrasilLogo")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.primary)
                        .opacity(0.1)
                        .frame(maxWidth: 200, alignment: .bottom)
                        .padding(.all, 24)
                }
                .navigationSplitViewColumnWidth(200)
                .listStyle(.sidebar)
            } detail: {
                StatusView()
            }
            .navigationTitle("Yggdrasil")
            .navigationSplitViewStyle(.automatic)
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .background:
                    Application.appDelegate.becameBackground()
                case .inactive:
                    Application.appDelegate.becameInactive()
                case .active:
                    Application.appDelegate.becameActive()
                @unknown default:
                    break
                }
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
