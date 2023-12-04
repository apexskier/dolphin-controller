import Foundation
import Network
import Combine

let pingInterval: TimeInterval = 1
let maxPingCount = 5

final class ControllerConnection: Identifiable {
    internal var id = UUID() // this allows using this in more swiftui places

    let connection: NWConnection
    private let didClose: (Error?) -> Void
    private let connectionReady: () -> Void
    private let didPickControllerNumber: (UInt8) -> Void
    private let onCemuhookInformation: (OutgoingControllerData) -> Void
    var lastControllerData: OutgoingControllerData? = nil

    let errorPublisher = PassthroughSubject<Error, Never>()

    init(
        connection: NWConnection,
        didClose: @escaping (Error?) -> Void,
        connectionReady: @escaping () -> Void,
        didPickControllerIndex: @escaping (UInt8) -> Void,
        onCemuhookInformation: @escaping (OutgoingControllerData) -> Void
    ) throws {
        self.connection = connection
        self.didClose = didClose
        self.connectionReady = connectionReady
        self.didPickControllerNumber = didPickControllerIndex
        self.onCemuhookInformation = onCemuhookInformation

        connection.stateUpdateHandler = self.handleStateUpdate
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    func disconnect() {
        if connection.state != .cancelled {
            connection.cancel()
        }
    }
    
    private func handleStateUpdate(state: NWConnection.State) {
        switch state {
        case .ready:
            self.connectionReady()
            receiveNextMessage()
        case .cancelled:
            didClose(nil)
        case .failed(let error):
            didClose(error)
        default:
            break
        }
    }
    
    private func receiveNextMessage() {
        if connection.state != .ready {
            print("connection not ready, stopping receiving")
            return
        }
        connection.receiveMessage { (content, context, isComplete, error) in
            if let error = error {
                self.connection.handleReceiveError(error: error)
                return
            }
            
            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: ControllerProtocol.definition) as? NWProtocolFramer.Message {
                guard var content = content else {
                    fatalError("missing content in \(message.controllerMessageType)")
                }
                switch message.controllerMessageType {
                case .cemuhookControllerData:
                    guard let data = content.withUnsafeMutableBytes({ pointer in
                        OutgoingControllerData(pointer)
                    }) else {
                        fatalError("failed to get outgoing controller data")
                    }
                    self.lastControllerData = data
                    self.onCemuhookInformation(data)
                case .pickController:
                    let controllerNumber = content.withUnsafeBytes { pointer in
                        pointer.load(as: UInt8.self)
                    }

                    self.didPickControllerNumber(controllerNumber)
                case .ping:
                    self.connection.sendControllerMessage(.pong, data: content)
                case .errorMessage:
                    let errorStr = String(data: content, encoding: .utf8) ?? "Unknown error"
                    self.errorPublisher.send(ControllerProtocol.ProtocolError.errorMessage(errorStr))
                case .pong, .controllerInfo:
                    fatalError("unexpected \(message.controllerMessageType) in server")
                }
            }
            
            // recurse to continue receiving messages
            self.receiveNextMessage()
        }
    }
}

extension ControllerConnection: Hashable {
    func hash(into: inout Hasher) {
        into.combine(id)
    }

    static func == (lhs: ControllerConnection, rhs: ControllerConnection) -> Bool {
        lhs.id == rhs.id
    }
}
