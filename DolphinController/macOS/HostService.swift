import Foundation
import MultipeerConnectivity
import Combine

func generateCode() -> String {
    String(format: "%04d", arc4random_uniform(9999))
}

class HostService: NSObject, ObservableObject {
    private let myPeerId = getPeerID(
        displayName: Host.current().localizedName ?? Host.current().name ?? "Unknown computer"
    )
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    @Published var hostCode = generateCode()
    
    @Published var knownPeers = [MCPeerID: KnownPeer]() {
        willSet {
            self.knownPeerSinks = newValue.map({ (key, value) in
                value.forwardChanges(to: self)
            })
        }
    }
    private var knownPeerSinks = [AnyCancellable]()
    
    lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self        
        self.serviceAdvertiser.startAdvertisingPeer()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
}

extension HostService: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let context = context,
              let providedCode = try? JSONDecoder().decode(String.self, from: context) else {
            invitationHandler(false, self.session)
            return
        }
        
        knownPeers[peerID] = KnownPeer(peer: peerID)
        invitationHandler(providedCode == hostCode, self.session)
    }

}

extension HostService: MCSessionDelegate {
    
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
