import Foundation
import Network
import Combine

let pingInterval: TimeInterval = 1
let maxPingCount = 5

final class ControllerConnection: Identifiable {
    internal var id = UUID()

    let connection: NWConnection
    private let didClose: (Error?) -> Void
    private let connectionReady: () -> Void
    private let didPickControllerNumber: (UInt8) -> Void

    let errorPublisher = PassthroughSubject<Error, Never>()

    private var pipe: ControllerFilePipe? = nil

    init(
        connection: NWConnection,
        didClose: @escaping (Error?) -> Void,
        connectionReady: @escaping () -> Void,
        didPickControllerIndex: @escaping (UInt8) -> Void
    ) throws {
        print("Creating controller connection: \(connection.debugDescription)")
        self.connection = connection
        self.didClose = didClose
        self.connectionReady = connectionReady
        self.didPickControllerNumber = didPickControllerIndex

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
        connection.receiveMessage { (content, context, isComplete, error) in
            if let error = error {
                if case .posix(let code) = error,
                   code == .ENODATA || code == .ECONNRESET {
                    print("Disconnected")
                    if self.connection.state != .cancelled {
                        self.connection.cancel()
                    }
                } else {
                    print("Error", error)
                }
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
                        if let errorData = "Controller number not chosen.".data(using: .utf8) {
                            self.connection.sendMessage(.errorMessage, data: errorData)
                        }
                        return
                    }
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
                case .pong, .errorMessage, .controllerInfo:
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
