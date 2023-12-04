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

    func send(on slot: UInt8, buttons2: ButtonsMask2) {
        let message = NWProtocolFramer.Message(
            cemuhookMessage: .controllerData(
                OutgoingControllerData(
                    controllerData: SharedControllerData(
                        slot: slot,
                        state: .connected,
                        model: .notApplicable,
                        connectionType: .notApplicable,
                        batteryStatus: .medium
                    ),
                    isConnected: true,
                    clientPacketNumber: packetCount,
                    buttons1: .dPadLeft,
                    buttons2: buttons2,
                    leftStickX: 128,
                    leftStickY: 128,
                    rightStickX: 128,
                    rightStickY: 128,
                    analogDPadLeft: 128,
                    analogDPadDown: 128,
                    analogDPadRight: 128,
                    analogDPadUp: 128,
                    analogY: 128,
                    analogB: 128,
                    analogA: 128,
                    analogX: 128,
                    analogR1: 128,
                    analogL1: 128,
                    analogR2: 128,
                    analogL2: 128,
                    firstTouch: TouchData(active: false, id: 0, xPos: 0, yPos: 0),
                    secondTouch: TouchData(active: false, id: 0, xPos: 0, yPos: 0),
                    motionTimestamp: 0,
                    accX: 0,
                    accY: 0,
                    accZ: 0,
                    gyroPitch: 0,
                    gyroYaw: 0,
                    gyroRoll: 0
                )
            )
        )
        let context = NWConnection.ContentContext(
            identifier: "outgoing version information cemuhook message contex",
            metadata: [message]
        )
        
        packetCount += 1
        
        connection.send(
            content: nil,
            contentContext: context,
            isComplete: true,
            completion: .idempotent
        )
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
