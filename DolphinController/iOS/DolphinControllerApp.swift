import SwiftUI

@main
struct DolphinControllerApp: App {
    let controllerService = ControllerService()
    let client = Client()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controllerService)
                .environmentObject(client)
        }
    }
}
