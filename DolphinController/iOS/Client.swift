import Combine
import Foundation
import UIKit
import Network

public class Client: ObservableObject {
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
        } else {
            lastServer = nil
            hasLastServer = false
        }
    }
    
    private var attemptsToReconnect = 0
    
    func reconnect() {
        if self.connection != nil {
            print("Skipping reconnect, still have a connection")
            return
        }
        guard let endpoint = lastServer else {
            print("Skipping reconnect, no last server")
            return
        }
        self.connect(to: endpoint)
    }
    
    func connect(to endpoint: Network.NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .custom())
        
        var hasBeenReplaced = false
        
        connection.stateUpdateHandler = { state in
            print("Connection state change", state)
            switch state {
            case .ready:
                self.connection = connection
                self.attemptsToReconnect = 0
                self.lastServer = endpoint
                let wrappedEndpoint = EndpointWrapper(endpoint)
                if let endpointData = try? NSKeyedArchiver.archivedData(withRootObject: wrappedEndpoint, requiringSecureCoding: false) {
                    Self.storage.setValue(
                        endpointData,
                        forKey: StorageKeys.lastUsedServer.rawValue
                    )
                }
                
                func receiveNextMessage() {
                    if hasBeenReplaced {
                        return
                    }
                    
                    connection.receiveMessage { (content, context, isComplete, error) in
                        if let error = error {
                            if case .posix(let code) = error {
                                switch code {
                                case .ENODATA:
                                    print("Disconnected by server")
                                case .ECONNABORTED:
                                    print("Connection aborted")
                                default:
                                    print("error", error)
                                }
                            } else {
                                print("Error", error)
                            }
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
                        
                        receiveNextMessage()
                    }
                }
                receiveNextMessage()
            case .failed(let error):
                print("Connection failed with error", error)
                connection.cancel()
                if !hasBeenReplaced {
                    self.connection = nil
                    if self.attemptsToReconnect < 3 {
                        self.attemptsToReconnect += 1
                        print("Attempting reconnect #\(self.attemptsToReconnect) after failure")
                        self.reconnect()
                    } else {
                        DispatchQueue.main.async {
                            self.controllerIndex = nil
                        }
                    }
                }
                hasBeenReplaced = true
            case .cancelled:
                print("Connection cancelled, handling gracefully")
                if !hasBeenReplaced {
                    self.connection = nil
                    DispatchQueue.main.async {
                        self.controllerIndex = nil
                    }
                }
                hasBeenReplaced = true
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

