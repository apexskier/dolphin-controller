import Foundation
import Combine
import Network

public class Server: ObservableObject {
    private let controllerListener: NWListener
    private var cemuhookListener: NWListener
    
    let name = "\(Host.current().localizedName ?? Host.current().name ?? "Unknown computer") - Dolphin Controller Server"

    @Published var broadcasting: Bool = false
    @Published var controllers: [UInt8: ControllerConnection?] = [:]
    @Published var bonjourPort: NWEndpoint.Port? = nil
    static var cemuhookPort = NWEndpoint.Port(integerLiteral: 26760)
    private var allControllers: [ControllerConnection] = []
    @Published var cemuhookClients: [CEMUHookClient] = []

    init() {
        self.controllerListener = try! NWListener(using: .controller())
        self.cemuhookListener = try! NWListener(using: .cemuhook(), on: Self.cemuhookPort)
        
        controllerListener.service = NWListener.Service(
            name: self.name,
            type: "_\(serviceType)._tcp.",
            domain: nil,
            txtRecord: nil
        )
        controllerListener.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                self.bonjourPort = self.controllerListener.port
                switch state {
                case .ready:
                    self.broadcasting = true
                default:
                    self.broadcasting = false
                }
            }
        }
        controllerListener.serviceRegistrationUpdateHandler = { change in
            DispatchQueue.main.async {
                self.bonjourPort = self.controllerListener.port
            }
        }
        controllerListener.newConnectionHandler = { connection in
            var index: UInt8? = nil

            var controllerConnection: ControllerConnection? = nil
            controllerConnection = try! ControllerConnection(
                connection: connection,
                didClose: { error in
                    DispatchQueue.main.async {
                        if let controllerConnection = controllerConnection,
                           let index = self.allControllers.firstIndex(of: controllerConnection) {
                            self.allControllers.remove(at: index)
                        }
                        if let i = index {
                            self.controllers[i] = nil
                        }
                        index = nil
                        self.sendControllerInfo()
                    }
                },
                connectionReady: {
                    self.sendControllerInfo()
                },
                didPickControllerIndex: { newIndex in
                    DispatchQueue.main.async {
                        if newIndex != index && self.controllers[newIndex] != nil {
                            self.sendError(error: "That controller is already taken.", to: connection)
                            return
                        }
                        if let i = index {
                            self.controllers[i] = nil
                        }
                        index = newIndex
                        self.controllers[newIndex] = controllerConnection
                        self.sendControllerInfo()
                    }
                },
                onCemuhookInformation: { data in
                    let message = NWProtocolFramer.Message(
                        cemuhookMessage: .controllerData(data)
                    )
                    let context = NWConnection.ContentContext(
                        identifier: "TODO",
                        metadata: [message]
                    )

                    for client in self.cemuhookClients {
                        client.connection.send(
                            content: nil,
                            contentContext: context,
                            isComplete: true,
                            completion: .idempotent
                        )
                    }
                }
            )

            DispatchQueue.main.async {
                if let controllerConnection = controllerConnection {
                    self.allControllers.append(controllerConnection)
                }
            }
        }
        
        cemuhookListener.newConnectionHandler = { connection in
            let client = CEMUHookClient(
                connection: connection,
                onCancel: { client in
                    DispatchQueue.main.async {
                        self.cemuhookClients.removeAll { $0 == client }
                    }
                },
                getControllers: {
                    self.controllers
                }
            )
            DispatchQueue.main.async {
                self.cemuhookClients.append(client)
            }
        }
    }

    private func getAvailableControllers() -> AvailableControllers {
        var availableControllers = AvailableControllers()
        for i in 0..<AvailableControllers.numberOfControllers {
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
        guard let data = error.data(using: .utf8) else {
            print("Failed to utf8 encode error string")
            return
        }
        connection.sendControllerMessage(.errorMessage, data: data)
    }

    func start() throws {
        controllerListener.start(queue: .global(qos: .userInitiated))
        cemuhookListener.start(queue: .global(qos: .userInitiated))
    }
    
    func stop() throws {
        controllerListener.cancel()
        cemuhookListener.cancel()
        print("Server closed")
    }
}
