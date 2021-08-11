import SwiftUI

@main
struct DolphinControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

//    let hostService = HostService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environmentObject(hostService)
                .environmentObject(appDelegate.server)
        }
            .commands {
                CommandGroup(replacing: .newItem) {}
            }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let server = Server()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        
        signal(SIGPIPE) { _ in
            // ignore sigpipes
        }
        
        try! server.start()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        try! server.stop()
    }
}
