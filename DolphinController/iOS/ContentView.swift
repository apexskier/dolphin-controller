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
    
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)
    var label: String
    
    var body: some View {
        Button(label) {}.pressAction(onPress: {
            client.send("PRESS \(label)")
            haptic.impactOccurred()
        }, onRelease: {
            client.send("RELEASE \(label)")
            haptic.impactOccurred()
        })
    }
}

struct ContentView: View {
    @EnvironmentObject var controllerService: ControllerService
    @EnvironmentObject var client: Client
    @State private var desiredHost: KnownPeer? = nil
    @State private var hostCode: String = ""
    @State private var error: Error? = nil
    @State private var mainDrag: DragGesture.Value? = nil {
        willSet {
            guard let value = newValue else {
                client.send("SET MAIN 0.5 0.5")
                return
            }
            
            if mainDrag == nil {
                mainHapticStart.impactOccurred()
            }
            
            let translation = value.translation
            let x = min(max(translation.width / 200, -0.5), 0.5)
            let y = min(max(-translation.height / 200, -0.5), 0.5)
            client.send("SET MAIN \(x+0.5) \(y+0.5)")
            let intensity = sqrt(x*2*x*2 + y*2*y*2)
            if (intensity > 1) {
                mainHaptic.impactOccurred()
            }
        }
    }
    @State private var cTranslation: CGSize? = nil {
        willSet {
            guard let value = newValue else {
                client.send("SET C 0.5 0.5")
                return
            }
            
            if cTranslation == nil {
                mainHapticStart.impactOccurred()
            }
            
            let x = min(max(value.width / 150, -0.5), 0.5)
            let y = min(max(-value.height / 150, -0.5), 0.5)
            client.send("SET C \(x+0.5) \(y+0.5)")
            let intensity = sqrt(x*2*x*2 + y*2*y*2)
            if (intensity > 1) {
                mainHaptic.impactOccurred()
            }
        }
    }
    
    private let mainHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let mainHapticStart = UIImpactFeedbackGenerator(style: .rigid)
    
    var body: some View {
        VStack {
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
            
            VStack {
                HStack {
                    PressButton(label: "L")
                        .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                    Spacer()
                    PressButton(label: "R")
                        .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                }
                .frame(
                  minWidth: 0,
                  maxWidth: .infinity,
                  alignment: .center
                )
                
                HStack {
                    VStack {
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(
                                    Color(red: 221/256, green: 218/256, blue: 231/256)
                                        .opacity(0.2)
                                )
                                .frame(width: 200, height: 200)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged({ value in
                                            self.mainDrag = value
                                        })
                                        .onEnded({ value in
                                            self.mainDrag = nil
                                        })
                                )
                            if let mainDrag = self.mainDrag {
                                Circle()
                                    .fill(
                                        Color(red: 221/256, green: 218/256, blue: 231/256)
                                            .opacity(0.5)
                                    )
                                    .frame(width: 50, height: 50)
                                    .position(
                                        x: mainDrag.startLocation.x + 25,
                                        y: mainDrag.startLocation.y - 25
                                    )
                                    .allowsHitTesting(false)
                                Circle()
                                    .fill(
                                        Color(red: 221/256, green: 218/256, blue: 231/256)
                                            .opacity(1)
                                    )
                                    .frame(width: 50, height: 50)
                                    .position(
                                        x: mainDrag.startLocation.x + mainDrag.translation.width + 25,
                                        y: mainDrag.startLocation.y + mainDrag.translation.height - 25
                                    )
                                    .allowsHitTesting(false)
                            } else {
                                Circle()
                                    .fill(
                                        Color(red: 221/256, green: 218/256, blue: 231/256)
                                            .opacity(0.5)
                                    )
                                    .frame(width: 50, height: 50)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        ZStack {
                            PressButton(label: "UP")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 50, y: 0)
                            PressButton(label: "DOWN")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 50, y: 100)
                            PressButton(label: "LEFT")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 0, y: 50)
                            PressButton(label: "RIGHT")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 100, y: 50)
                        }
                    }
                    
                    VStack {
                        HStack(alignment: .center, spacing: 20) {
                            if client.controllerIndex == 0 {
                                Rectangle().fill(Color.blue).frame(width: 12, height: 12)
                            } else {
                                Rectangle().fill(Color.gray).frame(width: 12, height: 12)
                            }
                            if client.controllerIndex == 1 {
                                Rectangle().fill(Color.blue).frame(width: 12, height: 12)
                            } else {
                                Rectangle().fill(Color.gray).frame(width: 12, height: 12)
                            }
                            if client.controllerIndex == 2 {
                                Rectangle().fill(Color.blue).frame(width: 12, height: 12)
                            } else {
                                Rectangle().fill(Color.gray).frame(width: 12, height: 12)
                            }
                            if client.controllerIndex == 3 {
                                Rectangle().fill(Color.blue).frame(width: 12, height: 12)
                            } else {
                                Rectangle().fill(Color.gray).frame(width: 12, height: 12)
                            }
                        }
                        
                        PressButton(label: "START")
                            .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                    }

                    VStack {
                        ZStack {
                            PressButton(label: "A")
                                .buttonStyle(GCCButton(color: Color(red: 55/256, green: 199/256, blue: 195/256)))
                            PressButton(label: "B")
                                .buttonStyle(GCCButton(color: Color(red: 232/256, green: 16/256, blue: 39/256)))
                                .position(x: 0, y: 240)
                            PressButton(label: "Y")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 100, y: 40)
                            PressButton(label: "X")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 200, y: 100)
                            PressButton(label: "Z")
                                .buttonStyle(GCCButton(color: Color(red: 221/256, green: 218/256, blue: 231/256)))
                                .position(x: 120, y: 240)
                        }
                        
                            ZStack(alignment: .center) {
                                Circle()
                                    .fill(Color(red: 254/256, green: 217/256, blue: 39/256).opacity(0.4))
                                    .frame(width: 150, height: 150)
                                Circle()
                                    .fill(Color(red: 254/256, green: 217/256, blue: 39/256))
                                    .frame(width: 50, height: 50)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged({ value in
                                                self.cTranslation = value.translation
                                            })
                                            .onEnded({ value in
                                                self.cTranslation = nil
                                            })
                                    )
                                    .offset(x: self.cTranslation?.width ?? 0, y: self.cTranslation?.height ?? 0)
                            }
                    }
                }
            }
            .frame(
              minWidth: 0,
              maxWidth: .infinity,
              minHeight: 0,
              maxHeight: .infinity,
              alignment: .center
            )
                
                
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
