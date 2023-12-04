import Foundation
import Network
import Combine

final class CEMUHookClient: Equatable {
    static func == (lhs: CEMUHookClient, rhs: CEMUHookClient) -> Bool {
        lhs.connection == rhs.connection
    }

    var connection: NWConnection
    var packetCount: UInt32 = 0

    let errorPublisher = PassthroughSubject<Error, Never>()
    let onCancel: (_ c: CEMUHookClient) -> Void
    let getControllers: () -> [UInt8: ControllerConnection?]

    init(connection: NWConnection, onCancel: @escaping (_ c: CEMUHookClient) -> Void, getControllers: @escaping () -> [UInt8: ControllerConnection?]) {
        self.connection = connection
        self.onCancel = onCancel
        self.getControllers = getControllers
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
            receiveNextMessage()
        case .cancelled:
            self.onCancel(self)
        case .failed(let error):
            self.errorPublisher.send(error)
        default:
            break
        }
    }

    private func receiveNextMessage() {
        connection.receiveMessage { (content, context, isComplete, error) in
            if let error = error {
                self.connection.handleReceiveError(error: error)
                return
            }

            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: CemuhookProtocol.definition) as? NWProtocolFramer.Message {
                switch message.incomingCemuhookMessage {
                case .connectedControllerInformation(let info):
                    let controllers = self.getControllers()
                    for slot in info.slotNumbers {
                        let connected = controllers[slot] != nil
                        let message = NWProtocolFramer.Message(
                            cemuhookMessage: .connectedControllerInformation(
                                OutgoingConnectedControllerInformation(
                                    controllerData: SharedControllerData(
                                        slot: slot,
                                        state: connected ? .connected : .notConnected,
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

                        self.connection.send(
                            content: nil,
                            contentContext: context,
                            isComplete: true,
                            completion: .idempotent
                        )
                    }
                case .controllerData(let data):
                    if data.actions.contains(.slotBaseRegistration) || data.actions.isEmpty {
                        print("TODO: registration")
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

                    self.connection.send(
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
