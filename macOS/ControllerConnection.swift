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
    private let didCommand: (ButtonsMask2) -> Void

    let errorPublisher = PassthroughSubject<Error, Never>()

    private var pipe: ControllerFilePipe? = nil

    init(
        connection: NWConnection,
        didClose: @escaping (Error?) -> Void,
        connectionReady: @escaping () -> Void,
        didPickControllerIndex: @escaping (UInt8) -> Void,
        didCommand: @escaping (ButtonsMask2) -> Void
    ) throws {
        self.connection = connection
        self.didClose = didClose
        self.connectionReady = connectionReady
        self.didPickControllerNumber = didPickControllerIndex
        self.didCommand = didCommand

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
                guard let content = content else {
                    fatalError("missing content in \(message.controllerMessageType)")
                }
                switch message.controllerMessageType {
                case .command:
                    guard let pipe = self.pipe else {
                        // controller number hasn't been chosen
                        return
                    }
                    var buttons2 = ButtonsMask2()
                    switch String(data: content, encoding: .utf8) {
                    case "PRESS A":
                        buttons2.insert(.a)
                    case "PRESS B":
                        buttons2.insert(.b)
                    case "PRESS X":
                        buttons2.insert(.x)
                    case "PRESS Y":
                        buttons2.insert(.y)
                    case "PRESS L":
                        buttons2.insert(.l1)
                    case "PRESS R":
                        buttons2.insert(.r1)
                    default:
                        break
                    }
                    
                    self.didCommand(buttons2)
                    do {
                        try pipe.streamText(data: content)
                    } catch {
                        self.errorPublisher.send(error)
                    }
                case .pickController:
                    let controllerNumber = content.withUnsafeBytes { pointer in
                        pointer.load(as: UInt8.self)
                    }

                    do {
                        self.pipe = try ControllerFilePipe(index: controllerNumber)
                        self.didPickControllerNumber(controllerNumber)
                    } catch {
                        self.errorPublisher.send(error)
                    }
                case .ping:
                    self.connection.sendMessage(.pong, data: content)
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
