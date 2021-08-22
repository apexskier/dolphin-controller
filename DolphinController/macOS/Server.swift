import Foundation
import Combine
import Network

enum ServerError: Error {
    case noOpenControllerPorts
}

public class Server: ObservableObject {
    private let netService: NWListener
    
    let name = "\(Host.current().localizedName ?? Host.current().name ?? "Unknown computer") Dolphin Controller"
    @Published var broadcasting: Bool = false
    @Published var controllers: [Int: ControllerConnection?] = [:]
    @Published var port: NWEndpoint.Port? = nil
    var controllerCount = 4
    
    var nextControllerIndex: Int? {
        for i in 0...controllerCount {
            if controllers[i] == nil {
                return i
            }
        }
        return nil
    }
    
    init() {
        self.netService = try! NWListener(using: .custom())
        netService.service = NWListener.Service(
            name: self.name,
            type: "_\(serviceType)._tcp.",
            domain: nil,
            txtRecord: nil
        )
        netService.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                self.port = self.netService.port
                switch state {
                case .ready:
                    self.broadcasting = true
                default:
                    self.broadcasting = false
                }
            }
        }
        netService.serviceRegistrationUpdateHandler = { change in
            DispatchQueue.main.async {
                self.port = self.netService.port
            }
            switch change {
            case .add(let endpoint):
                switch (endpoint) {
                case .hostPort(host: let host, port: let port):
                    print("Added host/port", host, port)
                case .service(name: let name, type: let type, domain: let domain, interface: let interface):
                    print("Added service", name, type, domain, interface)
                case .unix(path: let path):
                    print("Added unix", path)
                case .url(let url):
                    print("Added url", url)
                @unknown default:
                    fatalError()
                }
            case .remove(let endpoint):
                print("Removed \(endpoint)")
            @unknown default:
                fatalError()
            }
        }
        netService.newConnectionHandler = { connection in
            guard let index = self.nextControllerIndex else {
                connection.cancel()
                return
            }
            
            let controllerConnection = try! ControllerConnection(
                index: index,
                connection: connection
            ) { error in
                DispatchQueue.main.async {
                    self.controllers[index] = nil
                }
            }
            
            DispatchQueue.main.async {
                self.controllers[index] = controllerConnection
            }
        }
    }
    
    func start() throws {
        netService.start(queue: .global(qos: .userInitiated))
    }
    
    func stop() throws {
        netService.cancel()
        print("Server closed")
    }
}

enum PipeError: Error {
    case openFailed
}

func createPipe(index: Int) throws -> OutputStream {
    let applicationSupport = try FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    
    let pipesFolder = applicationSupport
        .appendingPathComponent("Dolphin")
        .appendingPathComponent("Pipes")
    if !FileManager.default.fileExists(atPath: pipesFolder.path) {
        try FileManager.default.createDirectory(
            at: pipesFolder,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    let pipeUrl = pipesFolder.appendingPathComponent("ctrl\(index+1)")
    mkfifo(pipeUrl.path, 0o644)
    guard let outputStream = OutputStream(url: pipeUrl, append: true) else {
        throw PipeError.openFailed
    }
    
    return outputStream
}
