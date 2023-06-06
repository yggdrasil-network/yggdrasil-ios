//
//  StatisticsView.swift
//  YggdrasilSwiftUI
//
//  Created by Neil on 10/02/2023.
//

import SwiftUI

struct PeersView: View {
    @State private var peers = ["Paul", "Taylor", "Adele"]
    
    @State private var multicastAdvertise = false
    @State private var multicastListen = false
    
    var body: some View {
        Form {
            Section(content: {
                ForEach(peers, id: \.self) { peer in
                    Text(peer)
                }
                .onDelete(perform: delete)
                Text("Yggdrasil will automatically attempt to connect to configured peers when started. If you configure more than one peer, your device may carry traffic on behalf of other network nodes. Avoid this by configuring only a single peer. Data charges may apply when using mobile data.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }, header: {
                Text("Configured peers")
            })
            
            Section(content: {
                Toggle(isOn: $multicastAdvertise) {
                    VStack(alignment: .leading) {
                        Text("Discoverable over multicast")
                        Text("Make your device discoverable to other Yggdrasil nodes on the same Wi-Fi network.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                Toggle(isOn: $multicastListen) {
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
            Button(role: nil, action: {
                
            }, label: {
                Image(systemName: "plus")
            })
            EditButton()
        }
        #endif
        .formStyle(.grouped)
        .navigationTitle("Peers")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    func delete(at offsets: IndexSet) {
       peers.remove(atOffsets: offsets)
    }
}

struct PeersView_Previews: PreviewProvider {
    static var previews: some View {
        PeersView()
    }
}
