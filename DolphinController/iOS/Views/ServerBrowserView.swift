import Combine
import Network
import SwiftUI

struct ServerBrowserView: View {
    @Binding var shown: Bool
    @ObservedObject private var serverBrowser = ServerBrowser()
    
    var didConnect: (NWEndpoint) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if !serverBrowser.servers.isEmpty {
                    List(serverBrowser.servers) { server in
                        Button(server.name) {
                            self.didConnect(server.endpoint)
                            self.shown = false
                        }
                    }
                }
                if serverBrowser.loading {
                    ProgressView("Searching")
                }
            }
            .navigationBarTitle("Server Browser")
            .navigationBarItems(trailing: Button("Close", action: {
                self.shown = false
            }))
        }
        .onAppear {
            serverBrowser.start()
        }
        .onDisappear {
            serverBrowser.stop()
        }
    }
}

struct ServerBrowser_Previews: PreviewProvider {
    static var previews: some View {
        ServerBrowserView(shown: Binding<Bool>(get: {
            true
        }, set: { _ in
            // noops
        })) { connection in
            print(connection)
        }
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

class ServerBrowser: NSObject, ObservableObject {
    private let browser: NWBrowser
    
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
        self.browser = NWBrowser(
            for: .bonjour(type: "_\(serviceType)._tcp.", domain: nil),
            using: parameters
        )
        
        super.init()
        
        browser.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.loading = true
                default:
                    self.loading = false
                }
            }
        }
        browser.browseResultsChangedHandler = { services, change in
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
    }
    
    deinit {
        stop()
    }
    
    func start() {
        browser.start(queue: .global(qos: .userInitiated))
    }
    
    func stop() {
        browser.cancel()
        loading = false
    }
}
