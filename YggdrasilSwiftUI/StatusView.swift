//
//  ContentView.swift
//  YggdrasilSwiftUI
//
//  Created by Neil on 10/02/2023.
//

import SwiftUI

#if os(iOS)
typealias MyListStyle = DefaultListStyle
#else
typealias MyListStyle = SidebarListStyle
#endif

struct StatusView: View {
    @ObservedObject private var appDelegate = Application.appDelegate
    
    @State private var statusBadgeColor: SwiftUI.Color = .gray
    @State private var statusBadgeText: String = "Not enabled"
    
    private func getStatusBadgeColor() -> SwiftUI.Color {
        if !appDelegate.yggdrasilSupported {
            return .gray
        } else if appDelegate.yggdrasilConnected {
            return .green
        } else if appDelegate.yggdrasilEnabled {
            return .yellow
        }
        return .gray
    }
    
    private func getStatusBadgeText() -> String {
        if !appDelegate.yggdrasilSupported {
            return "Not supported on this device"
        } else if !appDelegate.yggdrasilEnabled {
            return "Not enabled"
        } else if !appDelegate.yggdrasilConnected {
            return "No peers connected"
        } else {
            return "Connected to \(appDelegate.yggdrasilPeers.filter { $0.up }.count) peer(s)"
        }
    }
    
    var body: some View {
        Form {
            Section(content: {
                VStack(alignment: .leading) {
                    Toggle("Enable Yggdrasil", isOn: $appDelegate.yggdrasilEnabled)
                        .disabled(!appDelegate.yggdrasilSupported)
                        .padding(.bottom, 2)
                    HStack {
                        Image(systemName: "circlebadge.fill")
                            .foregroundColor(statusBadgeColor)
                            .onAppear(perform: {
                                statusBadgeColor = getStatusBadgeColor()
                            })
                            .onChange(of: appDelegate.yggdrasilSupported) { newValue in
                                statusBadgeColor = getStatusBadgeColor()
                            }
                            .onChange(of: appDelegate.yggdrasilEnabled) { newValue in
                                statusBadgeColor = getStatusBadgeColor()
                            }
                            .onChange(of: appDelegate.yggdrasilConnected) { newValue in
                                statusBadgeColor = getStatusBadgeColor()
                            }
                            .onChange(of: appDelegate.yggdrasilPeers.count) { newValue in
                                statusBadgeColor = getStatusBadgeColor()
                            }
                        Text(statusBadgeText)
                            .foregroundColor(.gray)
                            .font(.system(size: 11))
                            .onAppear(perform: {
                                statusBadgeText = getStatusBadgeText()
                            })
                            .onChange(of: appDelegate.yggdrasilSupported) { newValue in
                                statusBadgeText = getStatusBadgeText()
                            }
                            .onChange(of: appDelegate.yggdrasilEnabled) { newValue in
                                statusBadgeText = getStatusBadgeText()
                            }
                            .onChange(of: appDelegate.yggdrasilConnected) { newValue in
                                statusBadgeText = getStatusBadgeText()
                            }
                            .onChange(of: appDelegate.yggdrasilPeers.count) { newValue in
                                statusBadgeText = getStatusBadgeText()
                            }
                    }
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appDelegate.yggdrasilVersion())
                        .foregroundColor(Color.gray)
                }
            }, header: {
                Text("Status")
            })
            
            Section(content: {
                HStack {
                    Text("IP")
                    Spacer()
                    Text(appDelegate.yggdrasilIP)
                        .foregroundColor(Color.gray)
                        .truncationMode(.head)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
                HStack {
                    Text("Subnet")
                    Spacer()
                    Text(appDelegate.yggdrasilSubnet)
                        .foregroundColor(Color.gray)
                        .truncationMode(.head)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
                HStack {
                    Text("Public Key")
                    Spacer()
                    Text(appDelegate.yggdrasilPublicKey)
                        .foregroundColor(Color.gray)
                        .font(.system(size: 13, design: .monospaced))
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
            }, header: {
                Text("Details")
            })
            
            Section(content: {
                if self.appDelegate.yggdrasilPeers.count == 0 {
                    Text("No peers are connected")
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List(self.appDelegate.yggdrasilPeers.sorted(by: { a, b in
                        if a.up && !b.up {
                            return true
                        }
                        if !a.up && b.up {
                            return false
                        }
                        return a.remote < b.remote
                    }), id: \.remote) { peer in
                        VStack {
                            Text(peer.remote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .truncationMode(.tail)
                                .lineLimit(1)
                                .textSelection(.enabled)
                                .padding(.bottom, 2)
                            HStack {
                                Image(systemName: "circlebadge.fill")
                                    .foregroundColor(peer.getStatusBadgeColor())
                                    .onChange(of: peer.up) { newValue in
                                        statusBadgeColor = peer.getStatusBadgeColor()
                                    }
                                Text(peer.up ? peer.address ?? "Unknown IP address" : "Not connected")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 11))
                                    .truncationMode(.tail)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(.all, 2)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                    }
                }
            }, header: {
                Text("Peers")
            })
        }
        .formStyle(.grouped)
        .navigationTitle("Yggdrasil")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
    }
}
