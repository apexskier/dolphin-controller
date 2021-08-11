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
                            let tlsOptions = NWProtocolTLS.Options()
                            let allowInsecure = true
                            sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
                                let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
                                var error: CFError?
                                if SecTrustEvaluateWithError(trust, &error) {
                                    sec_protocol_verify_complete(true)
                                } else {
                                    if allowInsecure == true {
                                        sec_protocol_verify_complete(true)
                                    } else {
                                        sec_protocol_verify_complete(false)
                                    }
                                }
                            }, DispatchQueue.global(qos: .userInitiated))
                            let connection = NWConnection(to: server.endpoint, using: .custom())

                            connection.stateUpdateHandler = { state in
                                print("Connection state", state)
                                if let innerEndpoint = connection.currentPath?.localEndpoint,
                                   case .hostPort(let host, let port) = innerEndpoint {
                                    print(state, "connected on", "\(host):\(port)")
                                }
//                                let message = NWProtocolWebSocket.Metadata(opcode: .ping)
//                                let context = NWConnection.ContentContext(identifier: "send", metadata: [message])
//                                connection.send(
//                                    content: "HELLO".data(using: .utf8),
//                                    contentContext: context,
//                                    isComplete: true,
//                                    completion: .contentProcessed { err in
//                                        if let error = err {
//                                            print("ERROR", error)
//                                        } else {
//                                            print("SENT")
//                                        }
//                                    }
//                                )
                                switch state {
                                case .ready:
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
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        self.serviceBrowser = NWBrowser(
            for: .bonjour(type: "_\(serviceType)._tcp.", domain: nil),
            using: parameters
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
