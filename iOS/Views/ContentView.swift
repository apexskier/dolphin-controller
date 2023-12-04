import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var client: Client
    @Binding var shouldAutoReconnect: Bool
    @State private var hostCode: String = ""
    @State private var error: Error? = nil
    @State private var errorStr: String? = nil
    @State private var clientConnectionCancellable: AnyCancellable? = nil
    @State private var clientDisconnectionCancellable: AnyCancellable? = nil
    @State private var choosingConnection = false
    @State private var showingSettings = false
    @State private var ping: TimeInterval? = nil
    @AppStorage("showPing") private var showPing = false

    var body: some View {
        ZStack {
            if showPing {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        PingView(ping: self.ping)
                        Spacer()
                    }
                    Spacer()
                }
                    .onReceive(client.pingPublisher, perform: { duration in
                        self.ping = duration
                    })
            }
            ControllerView(
                playerIndicators: HStack(alignment: .center, spacing: 0) {
                    ForEach(0..<Int(AvailableControllers.numberOfControllers), id: \.self) { (i: Int) in
                        VStack(spacing: 4) {
                            LightView(
                                assigned: client.controllerInfo?.assignedController == UInt8(i),
                                available: client.controllerInfo?.availableControllers.contains(AvailableControllers[UInt8(i)])
                            )
                            Text("P\(i+1)")
                                .font(.custom("Futura-CondensedMedium", size: 16))
                                .foregroundColor(GameCubeColors.lightGray)
                        }
                            .frame(width: 48, height: 48)
                            .accessibilityLabel("Pick player \(i+1)")
                            .onTapGesture {
                                let available = client.controllerInfo?.availableControllers.contains(AvailableControllers[UInt8(i)])
                                if available == true {
                                    client.pickController(index: UInt8(i))
                                }
                            }
                    }
                },
                appButtons: HStack {
                    if self.client.connection == nil {
                        Button {
                            self.choosingConnection = true
                        } label: {
                            Text("Join")
                        }
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            shape: Capsule(style: .continuous),
                            fontSize: 20
                        ))
                    } else {
                        Button("Leave") {
                            self.shouldAutoReconnect = false
                            self.client.disconnect()
                        }
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            shape: Capsule(style: .continuous),
                            fontSize: 20
                        ))
                    }
                    Button {
                        self.showingSettings = true
                    } label: {
                        Text("Settings")
                    }
                    .buttonStyle(GCCButton(
                        color: GameCubeColors.lightGray,
                        shape: Capsule(style: .continuous),
                        fontSize: 20
                    ))
                }
            )
        }
            .padding()
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center
            )
            .onReceive(client.errorPublisher, perform: { error in
                self.error = error
            })
            .sheet(isPresented: $choosingConnection) {
                ServerBrowserView { endpoint in
                    self.client.connect(to: endpoint)
                    self.shouldAutoReconnect = true
                }
                    .environmentObject(client)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert(isPresented: Binding(get: {
                self.error != nil
            }, set: { (val: Bool) in
                self.error = nil
            })) {
                Alert(
                    title: Text("Error"),
                    message: Text(error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("Dismiss"))
                )
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Button(action: {
            print("pressed")
        }, label: {
            Text("B")
        }).buttonStyle(GCCButton(color: .red))
    }
}
