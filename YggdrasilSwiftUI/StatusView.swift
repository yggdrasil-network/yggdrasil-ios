//
//  ContentView.swift
//  YggdrasilSwiftUI
//
//  Created by Neil on 10/02/2023.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

#if os(iOS)
typealias MyListStyle = DefaultListStyle
#else
typealias MyListStyle = SidebarListStyle
#endif

struct StatusView: View {
    @ObservedObject private var appDelegate = Application.appDelegate
    
    @State private var statusBadgeColor: SwiftUI.Color = .gray
    @State private var statusBadgeText: String = "Not enabled"
    @State private var showingPublicKeyPopover = false
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    private func getStatusBadgeColor() -> SwiftUI.Color {
        if appDelegate.yggdrasilConnected {
            return .green
        } else if appDelegate.yggdrasilEnabled {
            return .yellow
        } else {
            return .gray
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
            return "Connected to \(appDelegate.yggdrasilPeers.filter { $0.up }.count) peer(s)"
        }
    }
    
    func formatBytes(bytes: Double) -> String {
        guard bytes > 0 else {
            return "N/A"
        }
        
        // Adapted from http://stackoverflow.com/a/18650828
        let suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        let k: Double = 1024
        let i = floor(log(bytes) / log(k))
        
        // Format number with thousands separator and everything below 1 GB with no decimal places.
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = i < 3 ? 0 : 1
        numberFormatter.numberStyle = .decimal
        
        let numberString = numberFormatter.string(from: NSNumber(value: bytes / pow(k, i))) ?? "Unknown"
        let suffix = suffixes[Int(i)]
        return "\(numberString) \(suffix)"
    }
    
#if os(iOS)
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
#endif
    
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
#if os(iOS)
                    if appDelegate.yggdrasilPublicKey != "N/A" {
                        Button("QR Code", systemImage: "qrcode", action: {
                            showingPublicKeyPopover = true
                        })
                        .labelStyle(.iconOnly)
                        .popover(isPresented: $showingPublicKeyPopover) {
                            Text("Public Key")
                                .font(.headline)
                                .padding()
                            Image(uiImage: generateQRCode(from: "\(appDelegate.yggdrasilPublicKey)"))
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                        }
                    }
#endif
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
                            HStack {
                                Text(peer.remote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .truncationMode(.tail)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                                    .padding(.bottom, 2)
                            }
                            HStack {
                                Image(systemName: "circlebadge.fill")
                                    .foregroundColor(peer.getStatusBadgeColor())
                                    .onChange(of: peer.up) { newValue in
                                        statusBadgeColor = peer.getStatusBadgeColor()
                                    }
                                Text(peer.up ? "Connected" : "Not connected")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 11))
                                    .truncationMode(.tail)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                                if peer.up {
                                    Spacer()
                                    if let uptime = peer.uptime {
                                        Label(Duration(secondsComponent: uptime/1000000000, attosecondsComponent: 0).formatted(), systemImage: "clock")
                                            .font(.system(size: 11))
                                            .labelStyle(.titleAndIcon)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let rxBytes = peer.rxBytes {
                                        Label(formatBytes(bytes: rxBytes), systemImage: "arrowshape.down")
                                            .font(.system(size: 11))
                                            .labelStyle(.titleAndIcon)
                                            .foregroundStyle(.teal)
                                    }
                                    if let txBytes = peer.txBytes {
                                        Label(formatBytes(bytes: txBytes), systemImage: "arrowshape.up")
                                            .font(.system(size: 11))
                                            .labelStyle(.titleAndIcon)
                                            .foregroundStyle(.purple)
                                    }
                                }
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
