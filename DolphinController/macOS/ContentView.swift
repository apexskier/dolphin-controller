import SwiftUI

struct ContentView: View {
    @EnvironmentObject var server: Server
    
    var body: some View {
        VStack {
//            Text("Code: \(hostService.hostCode)")
            
            List(server.controllers) { controller in
                Text("\(controller.channel.localAddress?.description ?? "<unknown>")")
            }
            
//            List(hostService.knownPeers.values.sorted(by: { a, b in
//                a.peer.displayName > b.peer.displayName
//            })) { peer in
//                HStack {
//                    Text("\(peer.peer.displayName)")
//                    Text("\(peer.connectionStatus.description)")
//                }
//            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
