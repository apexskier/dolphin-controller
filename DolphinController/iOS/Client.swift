import Combine
import Foundation
import UIKit
import Network

public class Client: ObservableObject {
    public var connection: NWConnection? = nil {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var controllerIndex: Int? = nil
    
    private func receiveNextMessage() {
        guard let connection = connection else {
            return
        }

        connection.receiveMessage { (content, context, isComplete, error) in
            if let error = error {
                if case .posix(let code) = error,
                   code == .ENODATA { // indicates a disconnect
                    connection.cancel()
                } else {
                    print("Error", error)
                    connection.cancel()
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
            if error == nil {
                // Continue to receive more messages until you receive and error.
                self.receiveNextMessage()
            } else {
                fatalError(error!.debugDescription)
            }
        }
    }
    
    func connect(connection: NWConnection) {
        self.connection = connection
        
        connection.stateUpdateHandler = { state in
            print("connection state change", state)
            switch state {
            case .ready:
                self.receiveNextMessage()
            case .failed(let error):
                print("\(connection) failed with error", error)
                connection.cancel()
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
