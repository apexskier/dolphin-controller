import SwiftUI

struct GCCButton: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(color)
            .foregroundColor(.black.opacity(0.3))
            .clipShape(Capsule())
    }
}

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    @State var pressed = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ test in
                        if !pressed {
                            onPress()
                            pressed = true
                        }
                    })
                    .onEnded({ _ in
                        onRelease()
                        pressed = false
                    })
            )
    }
}

extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: {
            onPress()
        }, onRelease: {
            onRelease()
        }))
    }
}

struct PressButton: View {
    @EnvironmentObject var client: Client
    
    var label: String
    
    var body: some View {
        Button(label) {}.pressAction(onPress: {
            client.send("PRESS \(label)")
        }, onRelease: {
            client.send("RELEASE \(label)")
        })
    }
}

struct ContentView: View {
    @EnvironmentObject var controllerService: ControllerService
    @EnvironmentObject var client: Client
    @State private var desiredHost: KnownPeer? = nil
    @State private var hostCode: String = ""
    @State private var error: Error? = nil
    
    var body: some View {
        VStack {
            Text("Hello, world (controller)!")
                .padding()
            if (client.channel == nil) {
                Button("connect client") {
                    do {
                        try client.connect()
                    } catch {
                        self.error = error
                    }
                }
                    .padding()
                    .disabled(client.channel != nil)
            }
            if let i = client.controllerIndex {
                Text("\(i+1)")
            }
            PressButton(label: "A")
                .buttonStyle(GCCButton(color: Color(red: 55/256, green: 199/256, blue: 195/256)))
            PressButton(label: "B")
                .buttonStyle(GCCButton(color: Color(red: 232/256, green: 16/256, blue: 39/256)))
            PressButton(label: "START")
                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
//            List(controllerService.knownPeers.values.sorted(by: { a, b in
//                a.peer.displayName > b.peer.displayName
//            })) { peer in
//                HStack {
//                    Text("\(peer.peer.displayName)")    
//                    Text("\(peer.connectionStatus.description)")
//                    Button("Connect") {
//                        desiredHost = peer
//                    }
//                    .disabled(peer.connectionStatus != .notConnected)
//                }
//            }
        }
        .sheet(item: $desiredHost, content: { host in
            TextField("Enter code", text: $hostCode)
                .keyboardType(.numberPad)
            HStack {
                Button("Cancel") {
                    hostCode = ""
                    desiredHost = nil
                }
                Button("Connect") {
                    controllerService.connect(to: host, code: hostCode)
                    desiredHost = nil
                }
                .disabled(hostCode.count != 4)
            }
        })
        .alert(isPresented: Binding(get: {
            self.error != nil
        }, set: { (val: Bool) in
            self.error = nil
        })) {
            Alert(
                title: Text("Error"),
                message: Text("An error occurred: \(error?.localizedDescription ?? "<unknown>")"),
                dismissButton: .default(Text("Dismiss"))
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
