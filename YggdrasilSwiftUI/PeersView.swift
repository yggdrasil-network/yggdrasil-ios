//
//  StatisticsView.swift
//  YggdrasilSwiftUI
//
//  Created by Neil on 10/02/2023.
//

import SwiftUI

struct PeersView: View {
    // @Binding public var yggdrasilConfiguration: ConfigurationProxy
    @ObservedObject private var appDelegate = Application.appDelegate
    
    var body: some View {
        Form {
            Section(content: {
                ForEach(Array(appDelegate.yggdrasilConfig.peers.enumerated()), id: \.offset) { index, peer in
                    HStack() {
                        Text(peer)
                        //TextField("", text: $yggdrasilConfiguration.peers[index])
                        //    .multilineTextAlignment(.leading)
#if os(macOS)
                        Spacer()
                        Button(role: .destructive) {
                            // appDelegate.yggdrasilConfig.peers.remove { $0 == peerURI }
                            // self.delete(at: appDelegate.yggdrasilConfig.peers.firstIndex { $0 == peerURI })
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
#endif
                    }
                }
                .onMove { indexSet, offset in
                    appDelegate.yggdrasilConfig.peers.move(fromOffsets: indexSet, toOffset: offset)
                }
                .onDelete { indexSet in
                    appDelegate.yggdrasilConfig.peers.remove(atOffsets: indexSet)
                }
                
                Button {
                    appDelegate.yggdrasilConfig.peers.append("foo")
                } label: {
                    Label("Add peer", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                
                Text("Yggdrasil will automatically attempt to connect to configured peers when started. If you configure more than one peer, your device may carry traffic on behalf of other network nodes. Avoid this by configuring only a single peer. Data charges may apply when using mobile data.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }, header: {
                Text("Configured peers")
            })
            
            Section(content: {
                Toggle(isOn: $appDelegate.yggdrasilConfig.multicastBeacons) {
                    VStack(alignment: .leading) {
                        Text("Discoverable over multicast")
                        Text("Make your device discoverable to other Yggdrasil nodes on the same Wi-Fi network.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                Toggle(isOn: $appDelegate.yggdrasilConfig.multicastListen) {
                    VStack(alignment: .leading) {
                        Text("Search for multicast peers")
                        Text("Automatically connect to discoverable Yggdrasil nodes on the same Wi-Fi network.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }, header: {
                Text("Local connectivity")
            })
        }
#if os(iOS)
        .toolbar {
           // EditButton()
        }
#endif
        .formStyle(.grouped)
        .navigationTitle("Peers")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

struct PeersView_Previews: PreviewProvider {
    static var previews: some View {
        PeersView()
    }
}
