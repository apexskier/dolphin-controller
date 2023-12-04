import Combine
import Foundation
import UIKit
import Network

let pingInterval: TimeInterval = 2
let maxPingCount = 5

class Client: ObservableObject {
    static let storage = UserDefaults.standard
    
    public var connection: NWConnection? = nil {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            idleManager?.update()
        }
    }

    let errorPublisher = PassthroughSubject<ControllerProtocol.ProtocolError, Never>()

    private var ping: (UUID, Date)? = nil
    private lazy var pingTimer: Timer? = nil
    let pingPublisher = PassthroughSubject<TimeInterval?, Never>()

    @Published var lastServer: NWEndpoint?
    @Published var controllerInfo: ClientControllerInfo? = nil

    public var idleManager: IdleManager? = nil
        
    init() {
        idleManager = IdleManager(client: self)
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
        let connection = NWConnection(to: endpoint, using: .controller())
        
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

                DispatchQueue.main.async {
                    self.pingTimer?.invalidate()
                    let pingTimer = Timer.scheduledTimer(
                        withTimeInterval: pingInterval,
                        repeats: true
                    ) { [weak self] t in
                        guard let self = self else {
                            return
                        }
                        var uuid = UUID()
                        let now = Date()
                        self.ping = (uuid, now)
                        let data = Data(bytes: &uuid, count: MemoryLayout<UUID>.size)
                        connection.sendMessage(.ping, data: data)
                    }
                    pingTimer.fire()
                    self.pingTimer = pingTimer
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
                            connection.handleReceiveError(error: error)
                            return
                        }

                        if let message = context?.protocolMetadata(definition: ControllerProtocol.definition) as? NWProtocolFramer.Message {
                            guard let content = content else {
                                fatalError("missing content in \(message.controllerMessageType)")
                            }

                            switch message.controllerMessageType {
                            case .controllerInfo:
                                let controllerInfo = content.withUnsafeBytes { pointer in
                                    pointer.load(as: ClientControllerInfo.self)
                                }
                                DispatchQueue.main.async {
                                    self.controllerInfo = controllerInfo
                                }
                            case .errorMessage:
                                let errorStr = String(data: content, encoding: .utf8) ?? "Unknown error"
                                self.errorPublisher.send(ControllerProtocol.ProtocolError.errorMessage(errorStr))
                            case .ping:
                                connection.sendMessage(.pong, data: content)
                            case .pong:
                                let uuid = content.withUnsafeBytes { pointer in
                                    pointer.load(as: UUID.self)
                                }
                                guard let lastPing = self.ping else {
                                    print("Pong without ping")
                                    DispatchQueue.main.async {
                                        self.pingPublisher.send(nil)
                                    }
                                    return
                                }
                                if lastPing.0 != uuid {
                                    print("Pong doesn't match ping")
                                    DispatchQueue.main.async {
                                        self.pingPublisher.send(nil)
                                    }
                                }
                                let now = Date()
                                let pingDuration = lastPing.1.distance(to: now)
                                DispatchQueue.main.async {
                                    self.pingPublisher.send(pingDuration)
                                }
                            case .command, .pickController, .cemuhookControllerData:
                                fatalError("unexpected message in client \(message.controllerMessageType)")
                            }
                        }
                        
                        receiveNextMessage()
                    }
                }
                receiveNextMessage()
            case .failed(let error):
                print("Connection failed with error", error)
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
                    self.pingTimer?.invalidate()
                    // there's an edge case where the connection is cancelled,
                    // but the app doesn't get the message until after it's
                    // resumed
                    if self.justAttemptedReconnect {
                        self.reconnect()
                    } else {
                        DispatchQueue.main.async {
                            self.controllerInfo = nil
                            self.pingPublisher.send(nil)
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
        var value = index
        let data = Data(bytes: &value, count: MemoryLayout<UInt8>.size)
        self.connection?.sendMessage(.pickController, data: data)
    }

    func send(_ content: String) {
        self.connection?.sendMessage(.command, data: Data(content.utf8))
    }
    
    func sendCemuhook(_ data: OutgoingControllerData) {
        self.connection?.sendMessage(.cemuhookControllerData, data: data.encodedData)
    }
    
    func disconnect() {
        self.connection?.cancel()
    }
}

