import Foundation
import MultipeerConnectivity

private let cachedPeerIDKey = "cachedPeerID"
private let cachedDisplayName = "cachedDisplayName"

func getPeerID(displayName: String) -> MCPeerID {
    if let oldDisplayName = UserDefaults.standard.string(forKey: cachedDisplayName),
       let peerIDData = UserDefaults.standard.data(forKey: cachedPeerIDKey),
       oldDisplayName == displayName,
       let peerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: peerIDData) {
        return peerID
    }
    let peerId = MCPeerID(displayName: displayName)
    if let peerIdData = try? NSKeyedArchiver.archivedData(withRootObject: peerId, requiringSecureCoding: true) {
        UserDefaults.standard.set(peerIdData, forKey: cachedPeerIDKey)
        UserDefaults.standard.set(displayName, forKey: cachedDisplayName)
        UserDefaults.standard.synchronize()
    }
    return peerId
}
