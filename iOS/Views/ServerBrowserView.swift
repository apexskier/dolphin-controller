import Combine
import Network
import SwiftUI

struct ServerBrowserView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var client: Client
    @ObservedObject private var serverBrowser = ServerBrowser()
    @State private var choosingManualConnection = false
    @AppStorage(StorageKeys.lastManualAddress.rawValue) private var manualServer = ""
    @State private var validatedServerParts: (host: String, portInt: UInt16)? = nil
    
    var didConnect: (NWEndpoint) -> Void

    private func lastServerIndicator(server: NWEndpoint) -> Text {
        Text(client.lastServer == server ? "\(Image(systemName: "star.fill")) " : "")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Local \(Image(systemName: "bonjour"))")) {
                        if !serverBrowser.servers.isEmpty {
                            ForEach(serverBrowser.servers) { server in
                                Button("\(self.lastServerIndicator(server: server.endpoint))\(server.name)") {
                                    self.didConnect(server.endpoint)
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                        } else if (serverBrowser.loading) {
                            ProgressView("Browsing").frame(maxWidth: .infinity)
                        }
                    }
                    Section(header: Text("Manual \(Image(systemName: "network"))")) {
                        HStack {
                            TextField("192.168.0.123:12345", text: $manualServer)
                                .disableAutocorrection(true)
                                .accessibilityLabel("Manually entered server address")
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Connect") {
                                guard let (host, portInt) = self.validatedServerParts else {
                                    return
                                }
                                self.didConnect(
                                    NWEndpoint.hostPort(
                                        host: .init(host),
                                        port: NWEndpoint.Port(integerLiteral: portInt)
                                    )
                                )
                                self.presentationMode.wrappedValue.dismiss()
                            }
                                .disabled(validatedServerParts == nil)
                                .onChange(of: manualServer, perform: self.validateManualServer)
                                .onAppear {
                                    self.validateManualServer(newManualServer: manualServer)
                                }
                        }
                    }
                }
            }
            .navigationBarTitle("Server Browser")
            .navigationBarItems(trailing: Button("Close", action: {
                self.presentationMode.wrappedValue.dismiss()
            }))
        }
        .onAppear {
            serverBrowser.start()
        }
        .onDisappear {
            serverBrowser.stop()
        }
    }
    
    func validateManualServer(newManualServer: String) {
        let parts = newManualServer.split(separator: ":")
        if parts.count != 2 {
            self.validatedServerParts = nil
            return
        }
        let host = String(parts[0])
        guard let portInt = UInt16(parts[1]) else {
            self.validatedServerParts = nil
            return
        }
        self.validatedServerParts = (host, portInt)
    }
}

struct ServerBrowser_Previews: PreviewProvider {
    static var previews: some View {
        ServerBrowserView { connection in
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
