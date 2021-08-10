import SwiftUI
import CoreHaptics
import Combine
import Network
import Foundation

@main
struct DolphinControllerApp: App {
//    let controllerService = ControllerService()
    let client = Client()
    @ObservedObject var test = ServerFinder()
    @State var showServers = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 106/256, green: 115/256, blue: 188/256)
                    .ignoresSafeArea()
                ContentView()
//                    .environmentObject(controllerService)
                    .environmentObject(client)
            }.sheet(isPresented: $showServers) {
                if test.loading {
                    ProgressView("Finding servers")
                }
                VStack {
                    List(test.servers) { server in
                        Text(server.name)
                        Button("Connect") {
                            let connection = NWConnection(to: server.endpoint, using: .tcp)

                            connection.stateUpdateHandler = { state in
                                if let innerEndpoint = connection.currentPath?.localEndpoint,
                                   case .hostPort(let host, let port) = innerEndpoint {
                                    print(state, "connected on", "\(host):\(port)")
                                }
                                switch state {
                                case .ready:
                                    connection.send(
                                        content: "HELLO".data(using: .utf8),
                                        completion: .contentProcessed({ err in
                                            if let error = err {
                                                print("ERROR", error)
                                            } else {
                                                print("SENT")
                                            }
                                        })
                                    )
                                    break
                                default:
                                    break
                                }
                            }
                            connection.start(queue: .global(qos: .userInitiated))
                        }
                    }
                }
            }
        }
    }
}

class ServerFinder: NSObject, ObservableObject {
    let serviceBrowser: NWBrowser
    
    @Published
    var loading: Bool = false
    
    @Published
    var servers = [Server]() {
        willSet {
            self.serversSinks = newValue.map({ value in
                value.forwardChanges(to: self)
            })
        }
    }
    private var serversSinks = [AnyCancellable]()
    
    override init() {
        self.serviceBrowser = NWBrowser(
            for: .bonjour(type: "_dolphinC._tcp.", domain: nil),
            using: .tcp
        )
        
        super.init()
        
        serviceBrowser.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.loading = true
                default:
                    self.loading = false
                }
            }
        }
        serviceBrowser.browseResultsChangedHandler = { services, change in
            let servers: [Server] = services.compactMap({ service in
                switch service.endpoint {
                case .service(name: let name, type: _, domain: _, interface: _):
                    return Server(name: name, endpoint: service.endpoint)
                default:
                    // ignore, we're only looking for bonjour services
                    return nil
                }
            })
            DispatchQueue.main.async {
                self.servers = servers
            }
        }
        
        serviceBrowser.start(queue: .global(qos: .userInitiated))
    }
    
    deinit {
        serviceBrowser.cancel()
        loading = false
    }
}

class Server: NSObject, ObservableObject, Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier("\(name)" as NSString)
    }
    
    let name: String
    let endpoint: NWEndpoint
    
    init(name: String, endpoint: NWEndpoint) {
        self.name = name
        self.endpoint = endpoint
        
        super.init()
    }
}
