import SwiftUI

struct GCCButton: ButtonStyle {
    var color: Color
    var width: CGFloat = 42
    var height: CGFloat = 42
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: width, height: height)
            .background(color)
            .foregroundColor(.black.opacity(0.2))
            // https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9
            .font(.custom("Futura-CondensedMedium", size: 30))
            .clipShape(Circle())
            .brightness(configuration.isPressed ? -0.1 : 0)
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

struct PressButton<Label>: View where Label: View {
    @EnvironmentObject var client: Client
    
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)
    var label: Label
    var identifier: String
    
    var body: some View {
        Button {
            // no direct tap action
        } label: {
            label
        }
        .pressAction(onPress: {
            client.send("PRESS \(label)")
            haptic.impactOccurred()
        }, onRelease: {
            client.send("RELEASE \(label)")
            haptic.impactOccurred()
        })
    }
}

private var grayColor = Color(red: 221/256, green: 218/256, blue: 231/256)

struct ContentView: View {
    @EnvironmentObject var controllerService: ControllerService
    @EnvironmentObject var client: Client
    @State private var desiredHost: KnownPeer? = nil
    @State private var hostCode: String = ""
    @State private var error: Error? = nil
    
    var body: some View {
        VStack {
            HStack {
                PressButton(label: Text("L"), identifier: "L")
                    .buttonStyle(GCCButton(color: grayColor))
                Spacer()
                PressButton(label: Text("R"), identifier: "R")
                    .buttonStyle(GCCButton(color: grayColor))
            }
                .frame(
                  minWidth: 0,
                  maxWidth: .infinity,
                  alignment: .center
                )
            
            HStack {
                VStack {
                    Joystick(
                        identifier: "MAIN",
                        color: Color(red: 221/256, green: 218/256, blue: 231/256),
                        diameter: 150,
                        label: Text("")
                    )
                    
                    ZStack {
                        PressButton(label: Image(systemName: "arrowtriangle.up.fill"), identifier: "UP")
                            .buttonStyle(GCCButton(color: grayColor))
                            .position(x: 50, y: 0)
                        PressButton(label: Image(systemName: "arrowtriangle.down.fill"), identifier: "DOWN")
                            .buttonStyle(GCCButton(color: grayColor))
                            .position(x: 50, y: 100)
                        PressButton(label: Image(systemName: "arrowtriangle.left.fill"), identifier: "LEFT")
                            .buttonStyle(GCCButton(color: grayColor))
                            .position(x: 0, y: 50)
                        PressButton(label: Image(systemName: "arrowtriangle.right.fill"), identifier: "RIGHT")
                            .buttonStyle(GCCButton(color: grayColor))
                            .position(x: 100, y: 50)
                    }
                }
                
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
                    
                    PressButton(label: EmptyView(), identifier: "START")
                        .buttonStyle(GCCButton(color: grayColor))
                }

                VStack {
                    ZStack {
                        PressButton(label: Text("A"), identifier: "A")
                            .buttonStyle(GCCButton(
                                color: Color(red: 55/256, green: 199/256, blue: 195/256),
                                width: 120,
                                height: 120
                            ))
                        PressButton(label: Text("B"), identifier: "B")
                            .buttonStyle(GCCButton(
                                color: Color(red: 232/256, green: 16/256, blue: 39/256),
                                width: 60,
                                height: 60
                            ))
                            .position(x: 0, y: 120)
                            .clipShape(Circle())
                        PressButton(label: Text("Y"), identifier: "Y")
                            .buttonStyle(GCCButton(color: grayColor))
                            .position(x: 100, y: 40)
                        PressButton(label: Text("X"), identifier: "X")
                            .buttonStyle(GCCButton(color: grayColor))
                            .position(x: 200, y: 100)
                        PressButton(label: Text("Z"), identifier: "Z")
                            .buttonStyle(GCCButton(color: Color(red: 72/256, green: 100/256, blue: 226/256)))
                            .position(x: 120, y: 240)
                    }
                    
                    Joystick(
                        identifier: "C",
                        color: Color(red: 254/256, green: 217/256, blue: 39/256),
                        diameter: 150,
                        label: Text("C")
                            .foregroundColor(.black.opacity(0.2))
                            // https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9
                            .font(.custom("Futura-CondensedMedium", size: 30))
                    )
                }
            }
        }
            .ignoresSafeArea()
            .frame(
              minWidth: 0,
              maxWidth: .infinity,
              minHeight: 0,
              maxHeight: .infinity,
              alignment: .center
            )
            .background(Color(red: 106/256, green: 115/256, blue: 188/256))
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
        Button(action: {
            print("pressed")
        }, label: {
            Text("B")
        }).buttonStyle(GCCButton(color: .red))
    }
}
