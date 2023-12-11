import SwiftUI

struct NetworkingInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var server: Server
    
    private let portFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.usesGroupingSeparator = false
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Networking")
                .font(.title)
            if let port = server.port?.rawValue,
               let formattedPort = portFormatter.string(from: NSNumber(value: port)) {
                Text("From your local network (e.g. on the same Wi-Fi connection), the server should automatically be discovered. To connect from across the internet, you must forward the port \(formattedPort).").fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No port has been allocated for the server yet.")
            }
            HStack {
                if let port = server.port?.rawValue,
                   let formattedPort = portFormatter.string(from: NSNumber(value: port)) {
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
            .frame(minWidth: 100, idealWidth: 420, minHeight: 100)
    }
}

#Preview {
    NetworkingInstructionsView()
}
