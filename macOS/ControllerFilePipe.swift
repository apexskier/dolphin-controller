import Foundation
import Network

private var newline: UInt8 = 0x0A

final class ControllerFilePipe {
    private var outputStream: OutputStream
    
    init(index: UInt8) throws {
        self.outputStream = try createPipe(index: index)
        DispatchQueue.global().async {
            self.outputStream.open()
        }
    }
    
    deinit {
        self.outputStream.close()
    }

    func streamText(data: Data) throws {
        if !self.outputStream.hasSpaceAvailable {
            return
        }
        self.outputStream.write([UInt8](data), maxLength: data.count)
        self.outputStream.write(&newline, maxLength: 1)
    }
}
