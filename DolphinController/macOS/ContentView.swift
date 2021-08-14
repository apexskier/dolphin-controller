import SwiftUI

struct ContentView: View {
    @EnvironmentObject var server: Server
    
    var connectedControllerCount: Int {
        server.controllers
            .compactMap({ $0.value })
            .count
    }
    
    var body: some View {
        VStack {
//            Image(systemName: server.broadcasting
//                    ? "antenna.radiowaves.left.and.right"
//                    : "antenna.radiowaves.left.and.right.slash")
            if let name = server.name {
                Text("Connect to \(name)")
                    .padding(.bottom)
            }
            HStack(alignment: .center, spacing: 20) {
                ForEach(0..<server.controllerCount) { i in
                    LightView(on: server.controllers[i] != nil)
                }
            }
                .padding(.bottom)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
