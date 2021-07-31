import SwiftUI

@main
struct DolphinControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    let hostService = HostService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hostService)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let server = Server(host: "0.0.0.0", port: 12345)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        try! server.run()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        try! server.shutdown()
    }
}
