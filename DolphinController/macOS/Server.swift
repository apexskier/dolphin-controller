import Foundation
import Network

enum ServerError: Error {
    case noOpenControllerPorts
}

class Controller: ObservableObject, Identifiable {
    var connection: NWConnection
    
    init(connection: NWConnection) {
        self.connection = connection
    }
}

public class Server: ObservableObject {
    private let netService: NWListener
    
    @Published var broadcasting: Bool = false
    @Published var controllers: [Int: Controller?] = [:]
    var controllerCount = 4
    
    var nextControllerIndex: Int? {
        for i in 0...controllerCount {
            if controllers[i] == nil {
                return i
            }
        }
        return nil
    }
    
    init() {
        self.netService = try! NWListener(using: .custom())
        netService.service = NWListener.Service(
//            name: "\(Host.current().localizedName ?? Host.current().name ?? "Unknown computer") - new",
            name: nil,
            type: "_\(serviceType)._tcp.",
            domain: nil,
            txtRecord: nil
        )
        netService.serviceRegistrationUpdateHandler = { change in
            print("NWListener service change: \(change)")
        }
        netService.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.broadcasting = true
                default:
                    self.broadcasting = false
                }
            }
        }
        netService.newConnectionHandler = { connection in
            guard let index = self.nextControllerIndex else {
                connection.cancel()
                return
            }
            
            let controller = Controller(connection: connection)
            DispatchQueue.main.async {
                self.controllers[index] = controller
            }
            print("NWListener connection \(connection.debugDescription)")
            connection.pathUpdateHandler = { path in
                print("connection path update", path)
            }
            connection.stateUpdateHandler = { state in
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
                    
                    let controllerConnection = try! ControllerConnection(index: index) {
                        print("Close")
                    }
                    
                    func receiveNextMessage() {
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
                                case .command:
                                    guard let content = content else {
                                        fatalError("missing content in command")
                                    }
                                    try! controllerConnection.streamText(data: content)
                                default:
                                    fatalError()
                                }
                            }
                            // Continue to receive more messages until you receive and error.
                            receiveNextMessage()
                        }
                    }
                    
                    receiveNextMessage()
                case .cancelled:
                    DispatchQueue.main.async {
                        self.controllers[index] = nil
                    }
                case .failed(let error):
                    print("Error", error)
                default:
                    break
                }
            }
            connection.viabilityUpdateHandler = { viability in
                print("connection viability update", viability)
            }
            connection.betterPathUpdateHandler = { betterPath in
                print("connection better path update", betterPath)
            }
            connection.start(queue: .global(qos: .userInitiated))
        }
    }
    
    func start() throws {
        netService.start(queue: .global(qos: .userInitiated))
    }
    
    func stop() throws {
        netService.cancel()
        print("Server closed")
    }
}

enum PipeError: Error {
    case openFailed
}

func createPipe(index: Int) throws -> OutputStream {
    let applicationSupport = try FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    
    let pipesFolder = applicationSupport
        .appendingPathComponent("Dolphin")
        .appendingPathComponent("Pipes")
    if !FileManager.default.fileExists(atPath: pipesFolder.path) {
        try FileManager.default.createDirectory(
            at: pipesFolder,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    let pipeUrl = pipesFolder.appendingPathComponent("ctrl\(index+1)")
    mkfifo(pipeUrl.path, 0o644)
    guard let outputStream = OutputStream(url: pipeUrl, append: true) else {
        throw PipeError.openFailed
    }
    
    return outputStream
}
