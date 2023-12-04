import SwiftUI

struct ClientConnectionInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var server: Server
    
    private let portFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.usesGroupingSeparator = false
        return f
    }()
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Cemuhook Clients")
                .font(.title)
            if server.cemuhookClients.isEmpty {
                Text("No clients known.")
            } else {
                Text("\(server.cemuhookClients.count) client\(server.cemuhookClients.count != 1 ? "s" : "") recently connected.")
            }
            ForEach(server.cemuhookClients) { client in
                Text("\(client.connection.endpoint.debugDescription)")
            }
            Text("Connect your emulator to http://127.0.0.1:\(portFormatter.string(from: NSNumber(value: Server.cemuhookPort.rawValue))!). For Dolphin, [here are the instructions](https://wiki.dolphin-emu.org/index.php?title=DSU_Client#Setting_up).").fixedSize(horizontal: false, vertical: true)
            HStack {
                if let formattedPort = portFormatter.string(from: NSNumber(value: Server.cemuhookPort.rawValue)) {
                    Button("Copy Port") {
                        NSPasteboard.general.clearContents()
                        if !NSPasteboard.general.setString(formattedPort, forType: .string) {
                            print("Failed to copy")
                        }
                    }
                }
                if (presentationMode.wrappedValue.isPresented) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
            // .textSelection(.enabled) // iOS 15
            .allowsTightening(true)
            .lineLimit(nil)
            .frame(minWidth: 100, idealWidth: 420)
    }
}

struct ClientConnectionInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        ClientConnectionInstructionsView()
    }
}
