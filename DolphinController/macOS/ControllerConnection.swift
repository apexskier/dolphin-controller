import Foundation
import Network

final class ControllerConnection {
    private let id = UUID()
    private let index: Int
    private var outputStream: OutputStream
    private var onClose: () -> Void

    private var writeQueue: DispatchQueue
    
    init(index: Int, onClose: @escaping () -> Void) throws {
        self.index = index
        self.onClose = onClose
        self.outputStream = try createPipe(index: index)
        self.writeQueue = DispatchQueue(
            label: "ctrl queue \(index)",
            qos: .userInteractive
        )
        DispatchQueue.global().async {
            self.outputStream.open()
        }
    }
    
    deinit {
        self.outputStream.close()
    }
    
    private static var newline: UInt8 = 0x0A

    func streamText(data: Data) throws {
        if !self.outputStream.hasSpaceAvailable {
            return
        }
        do {
            outputStream.write([UInt8](data), maxLength: data.count)
            self.outputStream.write(&Self.newline, maxLength: 1)
        } catch {
            if (error as NSError).domain == NSPOSIXErrorDomain
                && (error as NSError).code == EPIPE {
                print("pipe closed, reopening")
                // Broken pipe error
                self.outputStream = try createPipe(index: index)
                DispatchQueue.global().async {
                    self.outputStream.open()
                }
            }
            return
        }
    }
}
