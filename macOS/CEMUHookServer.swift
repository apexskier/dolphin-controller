import Foundation
import Network
import Combine

final class CEMUHookServer: Identifiable {
    private let listener: NWListener

    let name = "\(Host.current().localizedName ?? Host.current().name ?? "Unknown computer") - Dolphin Controller Server"

    internal var id = UUID() // this allows using this in more swiftui places

    var connection: NWConnection? = nil

    let errorPublisher = PassthroughSubject<Error, Never>()

    private let port = NWEndpoint.Port(integerLiteral: 26760)

    init() {
        self.listener = try! NWListener(using: .cemuhook(), on: self.port)
        listener.newConnectionLimit = 1
        listener.newConnectionHandler = { connection in
            self.connection = connection
            connection.stateUpdateHandler = self.handleStateUpdate
            connection.start(queue: .global(qos: .userInitiated))
        }
    }

    func start() throws {
        listener.start(queue: .global(qos: .userInitiated))
    }

    func stop() throws {
        listener.cancel()
        print("Server closed")
    }

    func disconnect() {
        if connection?.state != .cancelled {
            connection?.cancel()
        }
    }

    private func handleStateUpdate(state: NWConnection.State) {
        switch state {
        case .ready:
            receiveNextMessage()
        case .cancelled:
            self.connection = nil
        case .failed(let error):
            self.errorPublisher.send(error)
        default:
            break
        }
    }

    private func receiveNextMessage() {
        guard let connection = self.connection else {
            return
        }
        connection.receiveMessage { (content, context, isComplete, error) in
            if let error = error {
                connection.handleReceiveError(error: error)
                return
            }

            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: CemuhookProtocol.definition) as? NWProtocolFramer.Message {
                switch message.incomingCemuhookMessage {
                case .connectedControllerInformation(let info):
                    for slot in info.slotNumbers {
                        let message = NWProtocolFramer.Message(
                            cemuhookMessage: .connectedControllerInformation(
                                OutgoingConnectedControllerInformation(
                                    controllerData: SharedControllerData(
                                        slot: slot,
                                        state: .connected,
                                        model: .noOrPartialGyro,
                                        connectionType: .notApplicable,
                                        batteryStatus: .notApplicable
                                    )
                                )
                            )
                        )
                        let context = NWConnection.ContentContext(
                            identifier: "outgoing version information cemuhook message contex",
                            metadata: [message]
                        )

                        connection.send(
                            content: nil,
                            contentContext: context,
                            isComplete: true,
                            completion: .idempotent
                        )
                    }
                case .controllerData(let data):
                    //                    print(data)
                    if data.actions.contains(.slotBaseRegistration) || data.actions.isEmpty {
                        // start sending data for requested slot if connected
                    }
                    if data.actions.contains(.macBasedRegistration) || data.actions.isEmpty {
                        // start sending data for requested mac address
                        fatalError("TODO: not supported")
                    }
                case .versionInformation:
                    let message = NWProtocolFramer.Message(
                        cemuhookMessage: .versionInformation(
                            OutgoingVersionInformation(maxSupportedVersion: cemuhookVersion)
                        )
                    )
                    let context = NWConnection.ContentContext(
                        identifier: "outgoing version information cemuhook message contex",
                        metadata: [message]
                    )

                    connection.send(
                        content: nil,
                        contentContext: context,
                        isComplete: true,
                        completion: .idempotent
                    )
                case .none:
                    return
                }
            }

            // recurse to continue receiving messages
            self.receiveNextMessage()
        }
    }
}
