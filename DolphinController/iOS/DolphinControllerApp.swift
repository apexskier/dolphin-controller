import SwiftUI
import CoreHaptics
import Combine

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
                ProgressView("Finding servers")
                VStack {
                    List(test.servers) { server in
                        Text(server.name)
                        Button("Connect") {
                            server.service.resolve(withTimeout: 5)
                        }
                    }
                }
            }
        }
    }
}

class ServerFinder: NSObject, ObservableObject {
    let serviceBrowser = NetServiceBrowser()
    
    @Published
    var loading: Bool
    
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
        loading = true
        
        super.init()
        
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_dolphinC._tcp.", inDomain: "")
    }
    
    deinit {
        serviceBrowser.stop()
        loading = false
    }
}

class Server: NSObject, ObservableObject, Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier("\(address) \(name)" as NSString)
    }
    
    let address: String
    let name: String
    let service: NetService
    
    init(address: String, name: String, service: NetService) {
        self.address = address
        self.name = name
        self.service = service
        
        super.init()
        
        self.service.delegate = self
    }
}

extension Server: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses else {
            return
        }
        
        var ips = [String]()
        for addressData in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            addressData.withUnsafeBytes { pointer in
                guard let address = pointer.baseAddress else {
                    fatalError()
                }
                guard getnameinfo(
                    address.assumingMemoryBound(to: sockaddr.self),
                    socklen_t(addressData.count),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                ) == 0 else {
                    return
                }
            }
            ips.append(String(cString: hostname))
        }
        print(ips, sender.port)
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Failed to resolve")
    }
}

extension ServerFinder: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        loading = moreComing
        print("Found service", service.name)
        servers.append(Server(address: "unknown", name: service.name, service: service))
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        loading = moreComing
        print("Remove service", service.name)
        servers.removeAll { server in
            server.service == service
        }
    }
}
