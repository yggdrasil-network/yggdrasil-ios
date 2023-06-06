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
    @Binding public var yggdrasilConfiguration: ConfigurationProxy
    
    @ObservedObject private var appDelegate = Application.appDelegate
    
    @State private var statusBadgeColor: SwiftUI.Color = .gray
    @State private var statusBadgeText: String = "Not enabled"
    
    private func getStatusBadgeColor() -> SwiftUI.Color {
        if !appDelegate.yggdrasilEnabled {
            return .gray
        } else if !appDelegate.yggdrasilConnected {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func getStatusBadgeText() -> String {
        if !appDelegate.yggdrasilEnabled {
            return "Not enabled"
        } else if !appDelegate.yggdrasilConnected {
            return "Not connected"
        } else {
            return "Connected"
        }
    }
    
    var body: some View {
        Form {
            Section(content: {
                VStack(alignment: .leading) {
                    Toggle("Enable Yggdrasil", isOn: $appDelegate.yggdrasilEnabled)
                        .onTapGesture {
                            appDelegate.toggleYggdrasil()
                        }
                    HStack {
                        Image(systemName: "circlebadge.fill")
                            .foregroundColor(statusBadgeColor)
                            .onAppear(perform: {
                                statusBadgeColor = getStatusBadgeColor()
                            })
                            .onChange(of: appDelegate.yggdrasilEnabled) { newValue in
                                statusBadgeColor = getStatusBadgeColor()
                            }
                        Text(statusBadgeText)
                            .foregroundColor(.gray)
                            .font(.system(size: 11))
                            .onAppear(perform: {
                                statusBadgeText = getStatusBadgeText()
                            })
                            .onChange(of: appDelegate.yggdrasilEnabled) { newValue in
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
            })
            
            Section(content: {
                HStack {
                    Text("IP")
                    Spacer()
                    Text(appDelegate.yggdrasilIP)
                        .foregroundColor(Color.gray)
                }
                HStack {
                    Text("Subnet")
                    Spacer()
                    Text(appDelegate.yggdrasilSubnet)
                        .foregroundColor(Color.gray)
                }
                HStack {
                    Text("Coordinates")
                    Spacer()
                    Text(appDelegate.yggdrasilCoords)
                        .foregroundColor(Color.gray)
                }
                /*
                HStack {
                    Text("Public Key")
                    Spacer()
                    Text("N/A")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 15, design: .monospaced))
                        .truncationMode(.tail)
                }
                 */
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
        @State var config = ConfigurationProxy()
        
        StatusView(yggdrasilConfiguration: $config)
    }
}
