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
//            Text("Code: \(hostService.hostCode)")
            Text("\(connectedControllerCount) controller\(connectedControllerCount == 1 ? "" : "s") connected")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
