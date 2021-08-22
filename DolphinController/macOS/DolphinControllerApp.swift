import SwiftUI
import Combine

@main
struct DolphinControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @EnvironmentObject var server: Server
    
    @State var showAdvancedNetworking = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                GameCubeColors.purple.ignoresSafeArea()
                ContentView()
            }
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Image(systemName: "network").onTapGesture {
                        self.showAdvancedNetworking = true
                    }
                }
            }
            .foregroundColor(GameCubeColors.lightGray)
            .sheet(isPresented: self.$showAdvancedNetworking) {
                NetworkingSheet()
                    .padding()
            }
            .environmentObject(appDelegate.server)
        }
            .commands {
                CommandGroup(replacing: .newItem) {}
            }
            .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
            .windowStyle(HiddenTitleBarWindowStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
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
