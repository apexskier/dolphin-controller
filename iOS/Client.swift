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

    enum ClientError: LocalizedError {
        case serverError(String) // i know... weird naming

        public var errorDescription: String? {
            switch self {
            case .serverError(let str):
                return str
            }
        }
    }

    let errorPublisher = PassthroughSubject<ClientError, Never>()
    
    @Published var lastServer: NWEndpoint?
    @Published var controllerInfo: ClientControllerInfo? = nil
        
    init() {
        if let endpointData = Self.storage.value(forKey: StorageKeys.lastUsedServer.rawValue) as? Data,
           let endpointWrapper = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(endpointData) as? EndpointWrapper {
            lastServer = endpointWrapper.endpoint
        } else {
            lastServer = nil
        }
    }
    
    private var attemptsToReconnect = 0
    private var justAttemptedReconnect = false
    
    func reconnect() {
        justAttemptedReconnect = true
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
            self.justAttemptedReconnect = false
        }
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
            switch state {
            case .ready:
                self.connection = connection
                self.attemptsToReconnect = 0
                self.lastServer = endpoint
                let wrappedEndpoint = EndpointWrapper(endpoint)
                if let endpointData = try? NSKeyedArchiver.archivedData(
                    withRootObject: wrappedEndpoint,
                    requiringSecureCoding: false
                ) {
                    Self.storage.setValue(
                        endpointData,
                        forKey: StorageKeys.lastUsedServer.rawValue
                    )
                }

                if let index = self.controllerInfo?.assignedController {
                    self.pickController(index: index)
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
                            connection.cancel()
                            return
                        }
                        
                        if let message = context?.protocolMetadata(definition: ControllerProtocol.definition) as? NWProtocolFramer.Message {
                            switch message.controllerMessageType {
                            case .controllerInfo:
                                guard let content = content else {
                                    fatalError("missing content in controllerInfo")
                                }

                                let controllerInfo = content.withUnsafeBytes { pointer in
                                    pointer.load(as: ClientControllerInfo.self)
                                }
                                DispatchQueue.main.async {
                                    self.controllerInfo = controllerInfo
                                }
                            case .errorMessage:
                                guard let content = content else {
                                    fatalError("missing content in controllerInfo")
                                }
                                let errorStr = String(data: content, encoding: .utf8) ?? "Unknown error"

                                self.errorPublisher.send(ClientError.serverError(errorStr))
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
                            self.controllerInfo = nil
                        }
                    }
                }
                hasBeenReplaced = true
            case .cancelled:
                print("Connection cancelled, handling gracefully")
                if !hasBeenReplaced {
                    self.connection = nil
                    // there's an edge case where the connection is cancelled,
                    // but the app doesn't get the message until after it's
                    // resumed
                    if self.justAttemptedReconnect {
                        self.reconnect()
                    } else {
                        DispatchQueue.main.async {
                            self.controllerInfo = nil
                        }
                    }
                }
                hasBeenReplaced = true
            default:
                break
            }
        }
        
        connection.start(queue: .main)
    }

    func pickController(index: UInt8) {
        let message = NWProtocolFramer.Message(controllerMessageType: .pickController)
        let context = NWConnection.ContentContext(
            identifier: "PickController",
            metadata: [message]
        )

        var value = index
        self.connection?.send(
            content: Data(bytes: &value, count: MemoryLayout<UInt8>.size),
            contentContext: context,
            isComplete: true,
            completion: .idempotent
        )
    }

    func send(_ content: String) {
        guard let connection = self.connection else { return }
        let message = NWProtocolFramer.Message(controllerMessageType: .command)
        let context = NWConnection.ContentContext(
            identifier: "Command",
            metadata: [message]
        )
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

