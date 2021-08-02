import SwiftUI

struct ContentView: View {
    @EnvironmentObject var server: Server
    
    var body: some View {
        VStack {
//            Text("Code: \(hostService.hostCode)")
            Text("\(server.controllers.count) controller\(server.controllers.count == 1 ? "" : "s") connected")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
