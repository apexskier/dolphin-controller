import Foundation
import Network

// Don't change the explicit values assigned to these, in order to avoid
// accidental backwards incompatibility if order is changed in future
enum ControllerMessageType: UInt32, CustomDebugStringConvertible {
    case errorMessage = 0

    // sent from client to server
    // data: a string, to be passed to dolphin's pipe as a command (doesn't include newline)
    case command = 1

    // sent from server to client
    // send the available controller numbers
    // data: bitmask of available controller
    case controllerInfo = 2

    // sent from client to server
    // request a specific controller number
    // data: a single UInt8
    case pickController = 3

    var debugDescription: String {
        switch self {
        case .errorMessage:
            return "errorMessage"
        case .command:
            return "command"
        case .controllerInfo:
            return "controllerInfo"
        case .pickController:
            return "pickController"
        }
    }
}

struct ClientControllerInfo {
    let availableControllers: AvailableControllers
    let assignedController: UInt8?
}

struct AvailableControllers: OptionSet {
    let rawValue: UInt8

    static let numberOfControllers: UInt8 = 4
    static let range = 0..<numberOfControllers

    static subscript(index: UInt8) -> Self {
        guard range.contains(index) else {
            fatalError("Index of out range for available controllers")
        }

        return AvailableControllers(rawValue: 1 << index)
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
