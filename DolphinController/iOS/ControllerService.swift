import Foundation
import MultipeerConnectivity
import Combine

class ControllerService: NSObject, ObservableObject {
    private let myPeerId = getPeerID(displayName: UIDevice.current.name)
    private let serviceBrowser: MCNearbyServiceBrowser
    
    @Published var knownPeers = [MCPeerID: KnownPeer]() {
        willSet {
            self.knownPeerSinks = newValue.map({ (key, value) in
                value.forwardChanges(to: self)
            })
        }
    }
    private var knownPeerSinks = [AnyCancellable]()
    @Published var host: MCPeerID? = nil
    
    lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func connect(to peer: KnownPeer, code: String) {
        let context = try! JSONEncoder().encode(code)
        host = peer.peer
        serviceBrowser.invitePeer(peer.peer, to: session, withContext: context, timeout: 0)
    }
}

extension ControllerService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        knownPeers[peerID] = KnownPeer(peer: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        knownPeers.removeValue(forKey: peerID)
    }
    
}

extension ControllerService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let humanReadable: String = {
            switch state {
            case .connected:
                return "connected"
            case .connecting:
                return "connecting"
            case .notConnected:
                return "notConnected"
            @unknown default:
                fatalError("Unknown connection state")
            }
        }()
        NSLog("%@", "peer \(peerID) didChangeState: \(humanReadable)")

        if let player = knownPeers[peerID] {
            player.connectionStatus = state
        } else {
            NSLog("%@", "peer \(peerID) unknown: \(humanReadable)")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
}
