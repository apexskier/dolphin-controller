import Foundation
import Network
import Combine

final class ControllerConnection {
    private let connection: NWConnection
    private var pipe: ControllerFilePipe? = nil
    private let didClose: (Error?) -> Void
    private let connectionReady: () -> Void
    private let didPickControllerNumber: (UInt8) -> Void

    let errorPublisher = PassthroughSubject<Error, Never>()
    
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
        connection.cancel()
    }
    
    private func handleStateUpdate(state: NWConnection.State) {
        print("connection state update", state)
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
                    self.connection.cancel()
                } else {
                    print("Error", error)
                }
                return
            }
            
            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: ControllerProtocol.definition) as? NWProtocolFramer.Message {
                switch message.controllerMessageType {
                case .command:
                    guard let content = content else {
                        fatalError("missing content in command")
                    }
                    guard let pipe = self.pipe else {
                        print("no controller number chosen")
                        return
                    }
                    do {
                        try pipe.streamText(data: content)
                    } catch {
                        self.errorPublisher.send(error)
                    }
                case .pickController:
                    guard let content = content else {
                        fatalError("missing content in pickController")
                    }

                    let controllerNumber = content.withUnsafeBytes { pointer in
                        pointer.load(as: UInt8.self)
                    }

                    do {
                        self.pipe = try ControllerFilePipe(index: controllerNumber)
                        self.didPickControllerNumber(controllerNumber)
                    } catch {
                        self.errorPublisher.send(error)
                    }
                default:
                    fatalError("unexpected message type on server")
                }
            }
            
            // recurse to continue receiving messages
            self.receiveNextMessage()
        }
    }
}
