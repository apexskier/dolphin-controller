import SwiftUI
import CoreHaptics

@main
struct DolphinControllerApp: App {
    let controllerService = ControllerService()
    let client = Client()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 106/256, green: 115/256, blue: 188/256)
                    .ignoresSafeArea()
                ContentView()
                    .environmentObject(controllerService)
                    .environmentObject(client)
            }
        }
    }
}
