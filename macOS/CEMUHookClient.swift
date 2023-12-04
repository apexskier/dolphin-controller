import Foundation
import Network
import Combine

enum RegisteredSlots {
  case slots([UInt8])
  case all
}

final class CEMUHookClient: Equatable, Identifiable {
    internal var id = UUID() // this allows using this in more swiftui places
    
    static func == (lhs: CEMUHookClient, rhs: CEMUHookClient) -> Bool {
        lhs.connection == rhs.connection
    }

    var connection: NWConnection
    var packetCount: UInt32 = 0
    var disconnectTimer: Timer? = nil
    var registeredSlots: RegisteredSlots = .slots([])

    let errorPublisher = PassthroughSubject<Error, Never>()
    let onCancel: (_ c: CEMUHookClient) -> Void
    let getControllers: () -> [UInt8: ControllerConnection?]

    init(
        connection: NWConnection,
        onCancel: @escaping (_ c: CEMUHookClient) -> Void,
        getControllers: @escaping () -> [UInt8: ControllerConnection?]
    ) {
        self.connection = connection
        self.onCancel = onCancel
        self.getControllers = getControllers
        connection.stateUpdateHandler = self.handleStateUpdate
        connection.start(queue: .global(qos: .userInitiated))
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
            
            DispatchQueue.main.async {
                self.disconnectTimer?.invalidate()
                let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { t in
                    print("client lost")
                    if self.connection.state != .cancelled {
                        self.connection.cancel()
                    }
                }
                timer.tolerance = 2
                self.disconnectTimer = timer
            }

            // Extract your message type from the received context.
            if let message = context?.protocolMetadata(definition: CemuhookProtocol.definition) as? NWProtocolFramer.Message {
                switch message.incomingCemuhookMessage {
                case .connectedControllerInformation(let info):
                    let controllers = self.getControllers()
                    for slot in info.slotNumbers {
                        let controllerData = controllers[slot]??.lastControllerData?.controllerData ?? SharedControllerData.notConnected
                        let message = NWProtocolFramer.Message(
                            cemuhookMessage: .connectedControllerInformation(.init(controllerData: controllerData))
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
                    if data.actions.contains(.macBasedRegistration) {
                        fatalError("TODO: not supported")
                    }
                    if data.actions.contains(.slotBaseRegistration) {
                        if case .slots(var slots) = self.registeredSlots {
                            slots.append(data.slotBasedRegistrationSlot)
                        }
                    }
                    if data.actions.isEmpty {
                        self.registeredSlots = .all
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
