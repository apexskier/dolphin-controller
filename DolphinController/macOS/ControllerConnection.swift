import Foundation
import Network
import Combine

final class ControllerConnection {
    private let index: Int
    private let connection: NWConnection
    private let pipe: ControllerFilePipe
    private let didClose: (Error?) -> Void
    
    let errorPublisher = PassthroughSubject<Error, Never>()
    
    init(index: Int, connection: NWConnection, didClose: @escaping (Error?) -> Void) throws {
        print("Creating controller connection \(index): \(connection.debugDescription)")
        self.index = index
        self.connection = connection
        self.didClose = didClose
        self.pipe = try ControllerFilePipe(index: index)
        
        connection.stateUpdateHandler = self.handleStateUpdate
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    private func handleStateUpdate(state: NWConnection.State) {
        print("connection state update", state)
        switch state {
        case .ready:
            // Create a message object to hold the command type.
            let message = NWProtocolFramer.Message(controllerMessageType: .controllerNumberAssigned)
            let context = NWConnection.ContentContext(
                identifier: "Command",
                metadata: [message]
            )

            // Send the application content along with the message.
            var i = Int8(index)
            connection.send(
                content: Data(bytes: &i, count: MemoryLayout<Int8>.size),
                contentContext: context,
                isComplete: true,
                completion: .idempotent
            )
            
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
                    do {
                        try self.pipe.streamText(data: content)
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
