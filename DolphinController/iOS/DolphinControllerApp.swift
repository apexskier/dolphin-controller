import SwiftUI
import CoreHaptics
import Combine
import Foundation
import Network
import NetworkExtension

@main
struct DolphinControllerApp: App {
    @ObservedObject var client = Client()
    
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
