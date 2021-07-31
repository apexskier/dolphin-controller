import MultipeerConnectivity
import Foundation

extension MCSessionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .notConnected:
            return "Not Connected"
        @unknown default:
            return "Unknown connection state"
        }
    }
}

let serviceType = "dolphinC"

final class KnownPeer: ObservableObject, Identifiable {
    let peer: MCPeerID
    @Published var connectionStatus: MCSessionState = .notConnected
    
    init(peer: MCPeerID) {
        self.peer = peer
    }
}
