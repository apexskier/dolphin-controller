import SwiftUI
import CoreHaptics
import Combine
import Foundation
import Network
import NetworkExtension

@main
struct DolphinControllerApp: App {
    @ObservedObject var client = Client()
    @State var shouldAutoReconnect: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                GameCubeColors.purple.ignoresSafeArea()
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
            .ignoresSafeArea(edges: .top)
        }
    }
}
