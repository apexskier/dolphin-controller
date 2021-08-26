import Foundation
import Network

// Define the types of commands your game will use.
enum ControllerMessageType: UInt32 {
    case errorMessage = 0

    // sent from client to server
    // data: a string, to be passed to dolphin's pipe as a command (doesn't include newline)
    case command

    // sent from server to client
    // send the available controller numbers
    // data: bitmask of available controller
    case controllerInfo

    // sent from client to server
    // request a specific controller number
    // data: a single UInt8
    case pickController
}

struct ClientControllerInfo {
    let availableControllers: AvailableControllers
    let assignedController: UInt8?
}

struct AvailableControllers: OptionSet {
    let rawValue: UInt8

    static let one = AvailableControllers(rawValue: 1 << 0)
    static let two = AvailableControllers(rawValue: 1 << 1)
    static let three = AvailableControllers(rawValue: 1 << 2)
    static let four = AvailableControllers(rawValue: 1 << 3)

    static subscript(index: UInt8) -> Self {
        switch index {
        case 0:
            return Self.one
        case 1:
            return Self.two
        case 2:
            return Self.three
        case 3:
            return Self.four
        default:
            fatalError("Index of out range for available controllers")
        }
    }
}

// Create a class that implements a framing protocol.
class ControllerProtocol: NWProtocolFramerImplementation {
    // Create a global definition of your game protocol to add to connections.
    static let definition = NWProtocolFramer.Definition(implementation: ControllerProtocol.self)

    static var label: String {
        return "Controller"
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
        let type = message.controllerMessageType

        // Create a header using the type and length.
        let header = ControllerProtocolHeader(type: type.rawValue, length: UInt32(messageLength))

        // Write the header.
        framer.writeOutput(data: header.encodedData)

        // Ask the connection to insert the content of the application message after your header.
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        } catch let error {
            print("Error writing \(error)")
        }
    }

    // Whenever new bytes are available to read, try to parse out your message format.
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            // Try to read out a single header.
            var tempHeader: ControllerProtocolHeader? = nil
            let headerSize = ControllerProtocolHeader.encodedSize
            let parsed = framer.parseInput(
                minimumIncompleteLength: headerSize,
                maximumLength: headerSize
            ) { buffer, isComplete in
                guard let buffer = buffer else {
                    return 0
                }
                if buffer.count < headerSize {
                    return 0
                }
                tempHeader = ControllerProtocolHeader(buffer)
                return headerSize
            }

            // If you can't parse out a complete header, stop parsing and ask for headerSize more bytes.
            guard parsed, let header = tempHeader else {
                return headerSize
            }

            // Create an object to deliver the message.
            var messageType = ControllerMessageType.errorMessage
            if let parsedMessageType = ControllerMessageType(rawValue: header.type) {
                messageType = parsedMessageType
            }
            let message = NWProtocolFramer.Message(controllerMessageType: messageType)

            // Deliver the body of the message, along with the message object.
            if !framer.deliverInputNoCopy(length: Int(header.length), message: message, isComplete: true) {
                return 0
            }
        }
    }
}

// Extend framer messages to handle storing your command types in the message metadata.
extension NWProtocolFramer.Message {
    convenience init(controllerMessageType: ControllerMessageType) {
        self.init(definition: ControllerProtocol.definition)
        self["ControllerMessageType"] = controllerMessageType
    }

    var controllerMessageType: ControllerMessageType {
        if let type = self["ControllerMessageType"] as? ControllerMessageType {
            return type
        } else {
            return .errorMessage
        }
    }
}

// Define a protocol header struct to help encode and decode bytes.
struct ControllerProtocolHeader: Codable {
    let type: UInt32
    let length: UInt32

    init(type: UInt32, length: UInt32) {
        self.type = type
        self.length = length
    }

    init(_ buffer: UnsafeMutableRawBufferPointer) {
        var tempType: UInt32 = 0
        var tempLength: UInt32 = 0
        withUnsafeMutableBytes(of: &tempType) { typePtr in
            typePtr.copyMemory(
                from: UnsafeRawBufferPointer(
                    start: buffer.baseAddress!.advanced(by: 0),
                    count: MemoryLayout<UInt32>.size
                )
            )
        }
        withUnsafeMutableBytes(of: &tempLength) { lengthPtr in
            lengthPtr.copyMemory(
                from: UnsafeRawBufferPointer(
                    start: buffer.baseAddress!.advanced(by: MemoryLayout<UInt32>.size),
                    count: MemoryLayout<UInt32>.size
                )
            )
        }
        type = tempType
        length = tempLength
    }

    var encodedData: Data {
        var tempType = type
        var tempLength = length
        var data = Data(bytes: &tempType, count: MemoryLayout<UInt32>.size)
        data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt32>.size))
        return data
    }

    static var encodedSize: Int {
        return MemoryLayout<UInt32>.size * 2
    }
}
