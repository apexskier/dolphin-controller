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
                    .onReceive(NotificationCenter.default.publisher(for: AIntentNotificationName), perform: { _ in
                        print("press A intent handler")
                        client.send("PRESS A")
                        DispatchQueue.main.async {
                            let t = Timer.scheduledTimer(
                                withTimeInterval: 0.2,
                                repeats: false
                            ) { _ in
                                client.send("RELEASE A")
                            }
                            t.fire()
                        }
                    })
                    .onReceive(NotificationCenter.default.publisher(for: BIntentNotificationName), perform: { _ in
                        print("press B intent handler")
                        client.send("PRESS B")
                        DispatchQueue.main.async {
                            let t = Timer.scheduledTimer(
                                withTimeInterval: 0.2,
                                repeats: false
                            ) { _ in
                                client.send("RELEASE B")
                            }
                            t.fire()
                        }
                    })
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}
