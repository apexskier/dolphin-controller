import Foundation
import SwiftUI

@main
struct DolphinControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @EnvironmentObject var server: ControllerServer
    
    @State var showAdvancedNetworking = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                GameCubeColors.purple.ignoresSafeArea()
                ContentView()
                    .padding([.horizontal, .bottom])
            }
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Image(systemName: "network")
                        .accessibilityLabel("Show advanced networking information")
                        .onTapGesture {
                            self.showAdvancedNetworking = true
                        }
                }
            }
            .foregroundColor(GameCubeColors.lightGray)
            .frame(idealWidth: 380, idealHeight: 280)
            .sheet(isPresented: self.$showAdvancedNetworking) {
                NetworkingInstructionsView()
                    .padding()
            }
            .environmentObject(appDelegate.controllerServer)
        }
            .commands {
                CommandGroup(replacing: .newItem) {}
            }
            .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
            .windowStyle(HiddenTitleBarWindowStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let controllerServer = ControllerServer()
    let cemuHookServer = CEMUHookServer()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        
        signal(SIGPIPE) { _ in
            // ignore sigpipes
        }
        
        try! controllerServer.start()
        try! cemuHookServer.start()
        
        do {
            let applicationSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let actualConfigUrl = applicationSupport
                .appendingPathComponent("Dolphin")
                .appendingPathComponent("Config")
                .appendingPathComponent("GCPadNew.ini")
            if let requiredConfigUrl = Bundle.main.url(forResource: "GCPadNew", withExtension: "ini") {
                if !FileManager.default.contentsEqual(atPath: requiredConfigUrl.path, andPath: actualConfigUrl.path) {
                    if FileManager.default.isWritableFile(atPath: actualConfigUrl.path) {
                        try FileManager.default.removeItem(at: actualConfigUrl)
                        try FileManager.default.copyItem(at: requiredConfigUrl, to: actualConfigUrl)
                    }
                }
            }
        } catch {
            print("Error setting up config", error)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        try! controllerServer.stop()
        try! cemuHookServer.stop()
    }
}
