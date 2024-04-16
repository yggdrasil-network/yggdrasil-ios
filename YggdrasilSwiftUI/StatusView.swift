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
        } else if !appDelegate.yggdrasilEnabled {
            return .gray
        } else if !appDelegate.yggdrasilConnected {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func getStatusBadgeText() -> String {
        if !appDelegate.yggdrasilSupported {
            return "Not supported on this device"
        } else if !appDelegate.yggdrasilEnabled {
            return "Not enabled"
        } else if !appDelegate.yggdrasilConnected {
            return "No peers connected"
        } else {
            return "Connected to \(appDelegate.yggdrasilPeers.count) peer(s)"
        }
    }
    
    var body: some View {
        Form {
            Section(content: {
                VStack(alignment: .leading) {
                    Toggle("Enable Yggdrasil", isOn: $appDelegate.yggdrasilEnabled)
                        .disabled(!appDelegate.yggdrasilSupported)
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
                /*HStack {
                    Text("Coordinates")
                    Spacer()
                    Text(appDelegate.yggdrasilCoords)
                        .foregroundColor(Color.gray)
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }*/
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
            
            if self.appDelegate.yggdrasilEnabled {
                Section(content: {
                    List(self.appDelegate.yggdrasilPeers.sorted(by: { a, b in
                        a.key < a.key
                    }), id: \.remote) { peer in
                        VStack {
                            Text(peer.remote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .truncationMode(.tail)
                                .lineLimit(1)
                                .textSelection(.enabled)
                            Text(peer.address)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color.gray)
                                .font(.system(size: 11, design: .monospaced))
                                .truncationMode(.tail)
                                .lineLimit(1)
                                .textSelection(.enabled)
                        }
                        .padding(.all, 2)
                    }
                }, header: {
                    Text("Peers")
                })
            }
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
