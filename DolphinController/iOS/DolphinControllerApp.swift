import SwiftUI
import CoreHaptics
import Combine
import Foundation
import Network
import NetworkExtension

@main
struct DolphinControllerApp: App {
    @ObservedObject var client = Client()
    @State var shouldAutoReconnect: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 106/256, green: 115/256, blue: 188/256)
                    .ignoresSafeArea()
                ContentView(
                    shouldAutoReconnect: $shouldAutoReconnect
                )
                    .environmentObject(client)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        if shouldAutoReconnect {
                            client.reconnect()
                        }
                    }
            }
        }
    }
}
