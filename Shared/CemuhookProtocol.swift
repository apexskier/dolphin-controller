import Foundation
import Network

private enum MagicString: String {
    case server = "DSUS" // server (us)
    case client = "DSUC" // cemuhook
}

enum EventType: UInt32, CustomDebugStringConvertible, Codable {
    case versionInformation = 0x100000
    case connectedControllerInformation = 0x100001
    case controllerData = 0x100002

    var debugDescription: String {
        switch self {
        case .versionInformation:
            return "versionInformation"
        case .connectedControllerInformation:
            return "connectedControllerInformation"
        case .controllerData:
            return "controllerData"
        }
    }

    init?(_ buffer: UnsafeMutableRawBufferPointer) {
        self.init(rawValue: buffer.load(as: UInt32.self))
    }

    var encodedData: Data {
        var rawValue = self.rawValue
        return Data(bytes: &rawValue, count: MemoryLayout<RawValue>.size)
    }

    static var encodedSize: Int {
        return MemoryLayout<RawValue>.size
    }
}

let cemuhookVersion: UInt16 = 1001

protocol MessageDecodable {
    init?(_ buffer: UnsafeMutableRawBufferPointer)

    static var encodedSize: Int { get }
}

protocol MessageEncodable {
    var encodedData: Data { get }

    static var encodedSize: Int { get }
}

protocol MessageCodable: MessageDecodable, MessageEncodable {}

private struct CemuhookProtocolHeader: MessageCodable {
    let magicString: MagicString
    let version: UInt16
    let length: UInt16
    let crc32: UInt32
    let senderId: UInt32

    init(
        magicString: MagicString = .server,
        version: UInt16 = cemuhookVersion,
        length: UInt16,
        crc32: UInt32,
        senderId: UInt32
    ) {
        self.magicString = magicString
        self.version = version
        self.length = length
        self.crc32 = crc32
        self.senderId = senderId
    }

    init?(_ buffer: UnsafeMutableRawBufferPointer) {
        guard let rawMagicString = String(data: Data(buffer[0..<4]), encoding: .ascii),
              let magicString = MagicString(rawValue: rawMagicString) else {
            return nil
        }
        self.magicString = magicString
        self.version = buffer.load(fromByteOffset: 4, as: UInt16.self)
        self.length = buffer.load(fromByteOffset: 6, as: UInt16.self)
        self.crc32 = buffer.load(fromByteOffset: 8, as: UInt32.self)
        self.senderId = buffer.load(fromByteOffset: 12, as: UInt32.self)
    }

    var encodedData: Data {
        var data = Data()
        data.append(self.magicString.rawValue.data(using: .ascii)!)
        var tempVersion = version
        data.append(Data(bytes: &tempVersion, count: MemoryLayout.size(ofValue: tempVersion)))
        var tempLength = length
        data.append(Data(bytes: &tempLength, count: MemoryLayout.size(ofValue: tempVersion)))
        var tempCrc32 = crc32
        data.append(Data(bytes: &tempCrc32, count: MemoryLayout.size(ofValue: tempCrc32)))
        var tempSenderId = senderId
        data.append(Data(bytes: &tempSenderId, count: MemoryLayout.size(ofValue: tempSenderId)))
        return data
    }

    static var encodedSize: Int {
        return 16
    }
}

struct OutgoingVersionInformation: MessageEncodable {
    var maxSupportedVersion: UInt16 = cemuhookVersion

    var encodedData: Data {
        var tempVersion = maxSupportedVersion
        return Data(bytes: &tempVersion, count: Self.encodedSize)
    }

    static var encodedSize: Int {
        return MemoryLayout<UInt16>.size
    }
}

enum SlotState: UInt8 {
    case notConnected = 0
    case reserved = 1
    case connected = 2
}

enum DeviceModel: UInt8 {
    case notApplicable = 0
    case noOrPartialGyro = 1
    case fullGyro = 2
}

enum ConnectionType: UInt8 {
    case notApplicable = 0
    case usb = 1
    case bluetooth = 2
}

enum BatteryStatus: UInt8 {
    case notApplicable = 0
    case dying = 0x01
    case low = 0x02
    case medium = 0x03
    case high = 0x04
    case full = 0x05 // or almost
    case charging = 0xEE
    case charged = 0xEF
}

struct SharedControllerData: MessageEncodable {
    let slot: UInt8
    let state: SlotState
    let model: DeviceModel
    let connectionType: ConnectionType
//    let macAddress: ContiguousBytes // UInt48
    let batteryStatus: BatteryStatus

    var encodedData: Data {
        var data = Data()
        var tempSlot = slot
        data.append(Data(bytes: &tempSlot, count: MemoryLayout.size(ofValue: tempSlot)))
        var tempState = state
        data.append(Data(bytes: &tempState, count: MemoryLayout.size(ofValue: tempState)))
        var tempModel = model
        data.append(Data(bytes: &tempModel, count: MemoryLayout.size(ofValue: tempModel)))
        var tempConnectionType = connectionType
        data.append(Data(bytes: &tempConnectionType, count: MemoryLayout.size(ofValue: tempConnectionType)))
        data.append(contentsOf: [0, 0, 0, 0, 0, 0]) // mac address
        var tempBatteryStatus = batteryStatus
        data.append(Data(bytes: &tempBatteryStatus, count: MemoryLayout.size(ofValue: tempBatteryStatus)))
        return data
    }

    static var encodedSize: Int = 12
}

struct IncomingConnectedControllerInformation: MessageDecodable {
    let requestedSlotCount: Int32
    let slotNumbers: Array<UInt8>

    init(_ buffer: UnsafeMutableRawBufferPointer) {
        self.requestedSlotCount = buffer.load(fromByteOffset: 0, as: Int32.self)
        var slotNumbers: Array<UInt8> = []
        for i in 0..<requestedSlotCount {
            slotNumbers.append(buffer.load(fromByteOffset: MemoryLayout<Int32>.size+Int(i), as: UInt8.self))
        }
        self.slotNumbers = slotNumbers
    }

    static var encodedSize: Int = 12
}

struct OutgoingConnectedControllerInformation: MessageEncodable {
    let controllerData: SharedControllerData

    var encodedData: Data {
        var data = controllerData.encodedData
        data.append(0)
        return data
    }

    static var encodedSize: Int = 12
}

struct Actions: OptionSet {
    let rawValue: UInt8

    static let slotBaseRegistration = Actions(rawValue: 1 << 0)
    static let macBasedRegistration = Actions(rawValue: 1 << 1)
    // empty means subscribe to all
}

struct IncomingControllerData: MessageDecodable {
    let actions: Actions
    let slotBasedRegistrationSlot: UInt8
    let macBasedRegistrationMac: Data // UInt48

    init(_ buffer: UnsafeMutableRawBufferPointer) {
        self.actions = Actions(rawValue: buffer.load(fromByteOffset: 0, as: UInt8.self))
        self.slotBasedRegistrationSlot = buffer.load(fromByteOffset: 1, as: UInt8.self)
        self.macBasedRegistrationMac = Data(count: 6) // TODO
    }

    static var encodedSize: Int = 100 - ControllerProtocolHeader.encodedSize
}

struct ButtonsMask1: OptionSet {
    let rawValue: UInt8

    static let dPadLeft = ButtonsMask1(rawValue: 1 << 7) // dolphin doesn't use these
    static let dPadDown = ButtonsMask1(rawValue: 1 << 6) // dolphin doesn't use these
    static let dPadRight = ButtonsMask1(rawValue: 1 << 5) // dolphin doesn't use these
    static let dPadUp = ButtonsMask1(rawValue: 1 << 4) // dolphin doesn't use these
    static let options = ButtonsMask1(rawValue: 1 << 3)
    static let r3 = ButtonsMask1(rawValue: 1 << 2)
    static let l3 = ButtonsMask1(rawValue: 1 << 1)
    static let share = ButtonsMask1(rawValue: 1 << 0)
}

struct ButtonsMask2: OptionSet {
    let rawValue: UInt8

    static let y = ButtonsMask2(rawValue: 1 << 7) // dolphin doesn't use these
    static let b = ButtonsMask2(rawValue: 1 << 6) // dolphin doesn't use these
    static let a = ButtonsMask2(rawValue: 1 << 5) // dolphin doesn't use these
    static let x = ButtonsMask2(rawValue: 1 << 4) // dolphin doesn't use these
    static let r1 = ButtonsMask2(rawValue: 1 << 3) // dolphin doesn't use these
    static let l1 = ButtonsMask2(rawValue: 1 << 2) // dolphin doesn't use these
    static let r2 = ButtonsMask2(rawValue: 1 << 1) // dolphin doesn't use these
    static let l2 = ButtonsMask2(rawValue: 1 << 0) // dolphin doesn't use these
}

struct TouchData {
    let active: Bool // UInt8
    let id: UInt8
    let xPos: UInt16
    let yPos: UInt16
}

struct OutgoingControllerData: MessageEncodable {
    let controllerData: SharedControllerData
    let isConnected: Bool // UInt8
    let clientPacketNumber: UInt32
    let buttons1: ButtonsMask1
    let buttons2: ButtonsMask2
    let psButton: UInt8 = 0
    let touchButton: UInt8 = 0
    let leftStickX: UInt8 // plus rightward
    let leftStickY: UInt8 // plus upward
    let rightStickX: UInt8 // plus rightward
    let rightStickY: UInt8 // plus upward
    let analogDPadLeft: UInt8
    let analogDPadDown: UInt8
    let analogDPadRight: UInt8
    let analogDPadUp: UInt8
    let analogY: UInt8
    let analogB: UInt8
    let analogA: UInt8
    let analogX: UInt8
    let analogR1: UInt8
    let analogL1: UInt8
    let analogR2: UInt8
    let analogL2: UInt8
    let firstTouch: TouchData
    let secondTouch: TouchData
    let motionTimestamp: UInt64
    let accX: Float
    let accY: Float
    let accZ: Float
    let gyroPitch: Float
    let gyroYaw: Float
    let gyroRoll: Float

    var encodedData: Data {
        // TODO: this feels inefficient, can we preallocate 80 bytes?
        
        var data = controllerData.encodedData
        var temp_isConnected = isConnected
        data.append(Data(bytes: &temp_isConnected, count: MemoryLayout.size(ofValue: temp_isConnected)))
        var temp_clientPacketNumber = clientPacketNumber
        data.append(Data(bytes: &temp_clientPacketNumber, count: MemoryLayout.size(ofValue: temp_clientPacketNumber)))
        var temp_buttons1 = buttons1
        data.append(Data(bytes: &temp_buttons1, count: MemoryLayout.size(ofValue: temp_buttons1)))
        var temp_buttons2 = buttons2
        data.append(Data(bytes: &temp_buttons2, count: MemoryLayout.size(ofValue: temp_buttons2)))
        var temp_psButton = psButton
        data.append(Data(bytes: &temp_psButton, count: MemoryLayout.size(ofValue: temp_psButton)))
        var temp_touchButton = touchButton
        data.append(Data(bytes: &temp_touchButton, count: MemoryLayout.size(ofValue: temp_touchButton)))
        var temp_leftStickX = leftStickX
        data.append(Data(bytes: &temp_leftStickX, count: MemoryLayout.size(ofValue: temp_leftStickX)))
        var temp_leftStickY = leftStickY
        data.append(Data(bytes: &temp_leftStickY, count: MemoryLayout.size(ofValue: temp_leftStickY)))
        var temp_rightStickX = rightStickX
        data.append(Data(bytes: &temp_rightStickX, count: MemoryLayout.size(ofValue: temp_rightStickX)))
        var temp_rightStickY = rightStickY
        data.append(Data(bytes: &temp_rightStickY, count: MemoryLayout.size(ofValue: temp_rightStickY)))
        var temp_analogDPadLeft = analogDPadLeft
        data.append(Data(bytes: &temp_analogDPadLeft, count: MemoryLayout.size(ofValue: temp_analogDPadLeft)))
        var temp_analogDPadDown = analogDPadDown
        data.append(Data(bytes: &temp_analogDPadDown, count: MemoryLayout.size(ofValue: temp_analogDPadDown)))
        var temp_analogDPadRight = analogDPadRight
        data.append(Data(bytes: &temp_analogDPadRight, count: MemoryLayout.size(ofValue: temp_analogDPadRight)))
        var temp_analogDPadUp = analogDPadUp
        data.append(Data(bytes: &temp_analogDPadUp, count: MemoryLayout.size(ofValue: temp_analogDPadUp)))
        var temp_analogY = analogY
        data.append(Data(bytes: &temp_analogY, count: MemoryLayout.size(ofValue: temp_analogY)))
        var temp_analogB = analogB
        data.append(Data(bytes: &temp_analogB, count: MemoryLayout.size(ofValue: temp_analogB)))
        var temp_analogA = analogA
        data.append(Data(bytes: &temp_analogA, count: MemoryLayout.size(ofValue: temp_analogA)))
        var temp_analogX = analogX
        data.append(Data(bytes: &temp_analogX, count: MemoryLayout.size(ofValue: temp_analogX)))
        var temp_analogR1 = analogR1
        data.append(Data(bytes: &temp_analogR1, count: MemoryLayout.size(ofValue: temp_analogR1)))
        var temp_analogL1 = analogL1
        data.append(Data(bytes: &temp_analogL1, count: MemoryLayout.size(ofValue: temp_analogL1)))
        var temp_analogR2 = analogR2
        data.append(Data(bytes: &temp_analogR2, count: MemoryLayout.size(ofValue: temp_analogR2)))
        var temp_analogL2 = analogL2
        data.append(Data(bytes: &temp_analogL2, count: MemoryLayout.size(ofValue: temp_analogL2)))
        var temp_firstTouch = firstTouch
        data.append(Data(bytes: &temp_firstTouch, count: MemoryLayout.size(ofValue: temp_firstTouch)))
        var temp_secondTouch = secondTouch
        data.append(Data(bytes: &temp_secondTouch, count: MemoryLayout.size(ofValue: temp_secondTouch)))
        var temp_motionTimestamp = motionTimestamp
        data.append(Data(bytes: &temp_motionTimestamp, count: MemoryLayout.size(ofValue: temp_motionTimestamp)))
        var temp_accX = accX
        data.append(Data(bytes: &temp_accX, count: MemoryLayout.size(ofValue: temp_accX)))
        var temp_accY = accY
        data.append(Data(bytes: &temp_accY, count: MemoryLayout.size(ofValue: temp_accY)))
        var temp_accZ = accZ
        data.append(Data(bytes: &temp_accZ, count: MemoryLayout.size(ofValue: temp_accZ)))
        var temp_gyroPitch = gyroPitch
        data.append(Data(bytes: &temp_gyroPitch, count: MemoryLayout.size(ofValue: temp_gyroPitch)))
        var temp_gyroYaw = gyroYaw
        data.append(Data(bytes: &temp_gyroYaw, count: MemoryLayout.size(ofValue: temp_gyroYaw)))
        var temp_gyroRoll = gyroRoll
        data.append(Data(bytes: &temp_gyroRoll, count: MemoryLayout.size(ofValue: temp_gyroRoll)))
        return data
    }

    static var encodedSize: Int = 12
}

enum IncomingCemuhookMessage {
    case versionInformation
    case connectedControllerInformation(IncomingConnectedControllerInformation)
    case controllerData(IncomingControllerData)
}

enum OutgoingCemuhookMessage {
    case versionInformation(OutgoingVersionInformation)
    case connectedControllerInformation(OutgoingConnectedControllerInformation)
    case controllerData(OutgoingControllerData)
    case rawControllerData(Data)
}

// Create a class that implements a framing protocol.
class CemuhookProtocol: NWProtocolFramerImplementation {
    // Create a global definition of your game protocol to add to connections.
    static let definition = NWProtocolFramer.Definition(implementation: CemuhookProtocol.self)

    static var label: String {
        return "Cemuhook"
    }

    // Set the default behavior for most framing protocol functions.
    required init(framer: NWProtocolFramer.Instance) { }
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { return .ready }
    func wakeup(framer: NWProtocolFramer.Instance) { }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { return true }
    func cleanup(framer: NWProtocolFramer.Instance) { }

    // Whenever the application sends a message, add your protocol header and forward the bytes.
    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        // Extract the type of message.
        guard let message = message.outgoingCemuhookMessage else {
            print("Not a cemuhook message")
            return
        }

        let eventType: EventType
        let content: Data

        switch message {
        case .connectedControllerInformation(let info):
            eventType = .connectedControllerInformation
            content = info.encodedData
        case .controllerData(let controllerData):
            eventType = .controllerData
            content = controllerData.encodedData
        case .rawControllerData(let data):
            eventType = .controllerData
            content = data
        case .versionInformation:
            eventType = .versionInformation
            var tempVersion = cemuhookVersion
            content = Data(bytes: &tempVersion, count: MemoryLayout.size(ofValue: tempVersion))
        }

        // Create a header using the type and length.
        let header = CemuhookProtocolHeader(
            length: UInt16(1 + content.count),
            crc32: .zero,
            senderId: UInt32(123123) // TODO
        )

        var data = header.encodedData
        data.append(eventType.encodedData)
        data.append(content)

        let url = try! FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("temp")
        try! data.write(to: url)
        let crc32Value: UInt32 = CRC32.checksum(bytes: data)
        data.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: crc32Value, toByteOffset: 8, as: UInt32.self)
        }

        framer.writeOutput(data: data)

        // Ask the connection to insert the content of the application message after your header.
//        do {
//            try framer.writeOutputNoCopy(length: messageLength)
//        } catch let error {
//            print("Error writing \(error)")
//        }
    }

    // Whenever new bytes are available to read, try to parse out your message format.
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            var temp: IncomingCemuhookMessage? = nil
            var neededSize = CemuhookProtocolHeader.encodedSize + EventType.encodedSize
            let parsed = framer.parseInput(
                minimumIncompleteLength: neededSize,
                maximumLength: 100
            ) { buffer, isComplete in
                guard let buffer = buffer else {
                    return 0
                }
                if buffer.count < CemuhookProtocolHeader.encodedSize {
                    return 0
                }
                guard let header = CemuhookProtocolHeader(buffer) else {
                    print("WARNING, skipping inconsistent data in input stream")
                    return 1
                }
                neededSize = CemuhookProtocolHeader.encodedSize + Int(header.length)
                if buffer.count < CemuhookProtocolHeader.encodedSize + Int(header.length) {
                    return 0
                }
                guard let eventType = EventType(
                    UnsafeMutableRawBufferPointer(
                        start: buffer.baseAddress?.advanced(by: CemuhookProtocolHeader.encodedSize),
                        count: EventType.encodedSize
                    )
                ) else {
                    return 0
                }

                let messageBuffer = UnsafeMutableRawBufferPointer(
                    rebasing: buffer.dropFirst(CemuhookProtocolHeader.encodedSize + EventType.encodedSize)
                )
                switch eventType {
                case .versionInformation:
                    // no additional payload
                    break
                case .connectedControllerInformation:
                    temp = .connectedControllerInformation(IncomingConnectedControllerInformation(messageBuffer))
                case .controllerData:
                    temp = .controllerData(IncomingControllerData(messageBuffer))
                }
                return neededSize
            }
            guard parsed, let cemuhookMessage = temp else {
                return neededSize
            }

            // Create an object to deliver the message.
            let message = NWProtocolFramer.Message(cemuhookMessage: cemuhookMessage)

            // Deliver the body of the message, along with the message object.
            if !framer.deliverInputNoCopy(
                length: 0,
                message: message,
                isComplete: true
            ) {
                return 0
            }
        }
    }

    enum ProtocolError: LocalizedError {
        case errorMessage(String)

        public var errorDescription: String? {
            switch self {
            case .errorMessage(let str):
                return str
            }
        }
    }
}

// Extend framer messages to handle storing your command types in the message metadata.
extension NWProtocolFramer.Message {
//    fileprivate convenience init(cemuhookMessageType: EventType) {
//        self.init(definition: CemuhookProtocol.definition)
//        self["CemuhookMessageType"] = controllerMessageType
//    }
//
//    var cemuhookMessageType: EventType? {
//        return self["CemuhookMessageType"] as? EventType
//    }

    fileprivate convenience init(cemuhookMessage: IncomingCemuhookMessage) {
        self.init(definition: CemuhookProtocol.definition)
        self["IncomingCemuhookMessage"] = cemuhookMessage
    }

    var incomingCemuhookMessage: IncomingCemuhookMessage? {
        return self["IncomingCemuhookMessage"] as? IncomingCemuhookMessage
    }

    convenience init(cemuhookMessage: OutgoingCemuhookMessage) {
        self.init(definition: CemuhookProtocol.definition)
        self["OutgoingCemuhookMessage"] = cemuhookMessage
    }

    fileprivate var outgoingCemuhookMessage: OutgoingCemuhookMessage? {
        return self["OutgoingCemuhookMessage"] as? OutgoingCemuhookMessage
    }
}

