import Combine
import Foundation
import UIKit
import Network

//extension Optional: RawRepresentable where Wrapped == NWEndpoint {
//    public init?(rawValue: String) {
//        guard let data = rawValue.data(using: .utf8),
//              let result = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Self else {
//            return nil
//        }
//        self = result
//    }
//
//    public var rawValue: String {
//        guard let self = self else {
//            return ""
//        }
//        let data = try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
//        guard let result = String(data: data, encoding: .utf8) else {
//            return ""
//        }
//        return result
//    }
//}

public class Client: ObservableObject {
    enum StorageKeys: String {
        case lastUsedServer = "lastUsedServer"
    }
    
    static let storage = UserDefaults.standard
    
    public var connection: NWConnection? = nil {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    private var lastServer: NWEndpoint? {
        didSet {
            hasLastServer = lastServer != nil
        }
    }
    @Published var hasLastServer: Bool = false
    @Published var controllerIndex: Int? = nil
    
    init() {
        if let endpointData = Self.storage.value(forKey: StorageKeys.lastUsedServer.rawValue) as? Data,
           let endpointWrapper = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(endpointData) as? EndpointWrapper {
            lastServer = endpointWrapper.endpoint
            hasLastServer = true
        }
        lastServer = nil
        hasLastServer = false
    }
    
    private func receiveNextMessage() {
        guard let connection = connection else {
            return
        }

        connection.receiveMessage { (content, context, isComplete, error) in
            if let error = error {
                if case .posix(let code) = error,
                   code == .ENODATA { // indicates a disconnect
                    print("server closed?")
                } else {
                    print("Error", error)
                }
                connection.cancel()
                self.reconnect()
                return
            }
            
            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: ControllerProtocol.definition) as? NWProtocolFramer.Message {
                switch message.controllerMessageType {
                case .controllerNumberAssigned:
                    let number = content?.withUnsafeBytes { pointer in
                        Int(pointer.load(as: Int8.self))
                    }
                    DispatchQueue.main.async {
                        self.controllerIndex = number
                    }
                default:
                    fatalError("Unexpected message type")
                }
            }
            if error == nil {
                // Continue to receive more messages until you receive and error.
                self.receiveNextMessage()
            } else {
                fatalError(error!.debugDescription)
            }
        }
    }
    
    func reconnect() {
        guard let endpoint = lastServer else {
            return
        }
        self.connect(to: endpoint)
    }
    
    func connect(to endpoint: Network.NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .custom())
        self.connection = connection
        
        connection.stateUpdateHandler = { state in
            print("connection state change", state)
            switch state {
            case .ready:
                self.receiveNextMessage()
                self.lastServer = endpoint
                let wrappedEndpoint = EndpointWrapper(endpoint)
                if let endpointData = try? NSKeyedArchiver.archivedData(withRootObject: wrappedEndpoint, requiringSecureCoding: false) {
                    Self.storage.setValue(
                        endpointData,
                        forKey: StorageKeys.lastUsedServer.rawValue
                    )
                }
            case .failed(let error):
                print("\(connection) failed with error", error)
                connection.cancel()
                DispatchQueue.main.async {
                    self.controllerIndex = nil
                }
                self.reconnect()
            case .cancelled:
                self.connection = nil
                DispatchQueue.main.async {
                    self.controllerIndex = nil
                }
            default:
                break
            }
        }
        
        connection.start(queue: .main)
    }
    
    func send(_ content: String) {
        guard let connection = self.connection else { return }
        
        // Create a message object to hold the command type.
        let message = NWProtocolFramer.Message(controllerMessageType: .command)
        let context = NWConnection.ContentContext(
            identifier: "Command",
            metadata: [message]
        )

        // Send the application content along with the message.
        connection.send(
            content: Data(content.utf8),
            contentContext: context,
            isComplete: true,
            completion: .idempotent
        )
    }
    
    func disconnect() {
        self.connection?.cancel()
    }
}

protocol ControllerClientWebsocketHandlerDelegate {
    func didConnect(index: Int)
    func didDisconnect()
}

extension Client: ControllerClientWebsocketHandlerDelegate {
    func didConnect(index: Int) {
        DispatchQueue.main.sync {
            self.controllerIndex = index
        }
    }
    
    func didDisconnect() {
        DispatchQueue.main.sync {
            self.controllerIndex = nil
        }
    }
}
