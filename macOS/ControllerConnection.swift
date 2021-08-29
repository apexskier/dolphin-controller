import Foundation
import Network
import Combine

let pingInterval: TimeInterval = 1

final class ControllerConnection: Identifiable {
    internal var id = UUID()

    let connection: NWConnection
    private let didClose: (Error?) -> Void
    private let connectionReady: () -> Void
    private let didPickControllerNumber: (UInt8) -> Void

    let errorPublisher = PassthroughSubject<Error, Never>()
    var pingPublisher: AnyPublisher<TimeInterval?, Never> {
        AnyPublisher(_pingPublisher)
    }
    let _pingPublisher = PassthroughSubject<TimeInterval?, Never>()

    private var pipe: ControllerFilePipe? = nil

    private var pings: [UUID: Date] = [:]
    private lazy var pingTimer: Timer? = nil

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
            DispatchQueue.main.async {
                let pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] t in
                    guard let self = self else {
                        return
                    }
                    var uuid = UUID()
                    let now = Date()
                    self.pings[uuid] = now
                    let data = Data(bytes: &uuid, count: MemoryLayout<UUID>.size)
                    self.connection.sendMessage(.ping, data: data)
                }
                pingTimer.fire()
                self.pingTimer = pingTimer
            }
        case .cancelled:
            self.pingTimer?.invalidate()
            DispatchQueue.main.async {
                self._pingPublisher.send(nil)
            }
            didClose(nil)
        case .failed(let error):
            self.pingTimer?.invalidate()
            DispatchQueue.main.async {
                self._pingPublisher.send(nil)
            }
            didClose(error)
        default:
            DispatchQueue.main.async {
                self._pingPublisher.send(nil)
            }
            self.pingTimer?.invalidate()
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
                case .pong:
                    let uuid = content.withUnsafeBytes { pointer in
                        pointer.load(as: UUID.self)
                    }

                    guard let pingStart = self.pings[uuid] else {
                        print("Unexpected ping")
                        guard let data = "Unexpected ping".data(using: .utf8) else {
                            print("Failed to utf8 encode error string")
                            return
                        }
                        self.connection.sendMessage(.errorMessage, data: data)
                        return
                    }

                    let now = Date()
                    let pingDuration = pingStart.distance(to: now)
                    DispatchQueue.main.async {
                        self._pingPublisher.send(pingDuration)
                    }
                case .ping:
                    self.connection.sendMessage(.pong, data: content)
                case .errorMessage, .controllerInfo:
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
