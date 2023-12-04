import SwiftUI

struct ClientConnectionToolbarItem: View {
    @EnvironmentObject private var server: Server
    @Binding var showCemuhookConnection: Bool
    
    var body: some View {
        server.cemuhookClients.isEmpty
            ? Image(systemName: "bolt.badge.xmark")
                .accessibilityLabel("No CEMUHook clients known")
                .onTapGesture {
                    self.showCemuhookConnection = true
                }
            : Image(systemName: "bolt.badge.checkmark")
                .accessibilityLabel("CEMUHook client known")
                .onTapGesture {
                    self.showCemuhookConnection = true
                }
    }
}

#Preview {
    ClientConnectionToolbarItem(showCemuhookConnection: .constant(true))
}
