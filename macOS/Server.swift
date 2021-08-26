import Foundation
import Combine
import Network

struct ConnectionWrapper: Hashable, Identifiable {
    internal var id = UUID()

    static func == (lhs: ConnectionWrapper, rhs: ConnectionWrapper) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into: inout Hasher) {
        into.combine(id)
    }

    let connection: NWConnection
}

public class Server: ObservableObject {
    private let netService: NWListener
    
    let name = "\(Host.current().localizedName ?? Host.current().name ?? "Unknown computer") - Dolphin Controller Server"
    let controllerCount: UInt8 = 4

    @Published var broadcasting: Bool = false
    @Published var controllers: [UInt8: ConnectionWrapper?] = [:]
    @Published var port: NWEndpoint.Port? = nil
    private var allControllers: [ConnectionWrapper] = []

    init() {
        self.netService = try! NWListener(using: .custom())
        netService.service = NWListener.Service(
            name: self.name,
            type: "_\(serviceType)._tcp.",
            domain: nil,
            txtRecord: nil
        )
        netService.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                self.port = self.netService.port
                switch state {
                case .ready:
                    self.broadcasting = true
                default:
                    self.broadcasting = false
                }
            }
        }
        netService.serviceRegistrationUpdateHandler = { change in
            DispatchQueue.main.async {
                self.port = self.netService.port
            }
        }
        netService.newConnectionHandler = { connection in
            var index: UInt8? = nil

            let connectionWrapper = ConnectionWrapper(connection: connection)

            self.allControllers.append(connectionWrapper)

            _ = try! ControllerConnection(
                connection: connection
            ) { error in
                DispatchQueue.main.async {
                    if let i = index {
                        self.controllers[i] = nil
                    }
                    index = nil
                    self.sendControllerInfo()
                }
            } connectionReady: {
                self.sendControllerInfo()
            } didPickControllerIndex: { newIndex in
                if newIndex != index && self.controllers[newIndex] != nil {
                    self.sendError(error: "That controller is already taken.", to: connection)
                    return
                }
                DispatchQueue.main.async {
                    if let i = index {
                        self.controllers[i] = nil
                    }
                    index = newIndex
                    self.controllers[newIndex] = connectionWrapper
                    self.sendControllerInfo()
                }
            }
        }
    }

    private func getAvailableControllers() -> AvailableControllers {
        var availableControllers = AvailableControllers()
        for i in 0..<self.controllerCount {
            if self.controllers[i] == nil {
                availableControllers.insert(AvailableControllers[i])
            }
        }
        return availableControllers
    }

    private func sendControllerInfo() {
        let availableControllers = getAvailableControllers()
        let message = NWProtocolFramer.Message(controllerMessageType: .controllerInfo)
        let context = NWConnection.ContentContext(
            identifier: "ControllerInfo",
            metadata: [message]
        )
        for controller in self.allControllers {
            var controllerInfo = ClientControllerInfo(
                availableControllers: availableControllers,
                assignedController: controllers.first(where: { $0.value == controller })?.key
            )
            if controller.connection.state == .ready {
                DispatchQueue.global(qos: .userInitiated).async {
                    controller.connection.send(
                        content: Data(bytes: &controllerInfo, count: MemoryLayout<ClientControllerInfo>.size),
                        contentContext: context,
                        isComplete: true,
                        completion: .idempotent
                    )
                }
            }
        }
    }

    private func sendError(error: String, to connection: NWConnection) {
        guard connection.state == .ready else {
            print("Connection not ready to send error on")
            return
        }
        let message = NWProtocolFramer.Message(controllerMessageType: .errorMessage)
        let context = NWConnection.ContentContext(
            identifier: "Invalid",
            metadata: [message]
        )
        connection.send(
            content: error.data(using: .utf8),
            contentContext: context,
            isComplete: true,
            completion: .idempotent
        )
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

func createPipe(index: UInt8) throws -> OutputStream {
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
