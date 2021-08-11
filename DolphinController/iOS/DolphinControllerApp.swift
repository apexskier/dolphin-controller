import SwiftUI
import CoreHaptics
import Combine
import Network
import Foundation

@main
struct DolphinControllerApp: App {
    let client = Client()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 106/256, green: 115/256, blue: 188/256)
                    .ignoresSafeArea()
                ContentView()
                    .environmentObject(client)
            }
        }
    }
}
