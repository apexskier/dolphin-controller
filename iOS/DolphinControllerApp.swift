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

    @AppStorage("skin") private var skin = Skin.indigo

    var body: some Scene {
        WindowGroup {
            ZStack {
                skin.view.ignoresSafeArea()
                ContentView(
                    shouldAutoReconnect: $shouldAutoReconnect,
                    skin: $skin
                )
                    .environmentObject(client)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        if shouldAutoReconnect {
                            client.reconnect()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: AIntentNotificationName), perform: { _ in
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
            .environment(\.skin, skin)
        }
    }
}
