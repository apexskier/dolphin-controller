import Combine
import CoreGraphics
import SwiftUI

extension Font {
    // https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9
    static var gameCubeController = Self.custom("Futura-CondensedMedium", size: 30)
}

struct GCCButton<S>: ButtonStyle where S: Shape {
    var color: Color
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var shape: S
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: width, height: height)
            .background(color)
            .foregroundColor(.black.opacity(0.2))
            .font(.gameCubeController)
            .clipShape(shape)
            .brightness(configuration.isPressed ? -0.1 : 0)
    }
}

extension GCCButton where S == Circle {
    init(color: Color, width: CGFloat = 42, height: CGFloat = 42) {
        self.init(color: color, width: width, height: height, shape: Circle())
    }
}

struct CurvedPill: Shape {
    var radius: CGFloat = 0.4
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY),
            radius: rect.width * 0.1
        )
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY),
            radius: rect.width * 0.1
        )
        
        return path
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

struct Light: View {
    let on: Bool
    
    var body: some View {
        if on {
            return Rectangle()
                .fill(Color(red: 103/256, green: 197/256, blue: 209/256))
                .frame(width: 12, height: 12)
        } else {
            return Rectangle()
                .fill(Color(red: 107/256, green: 111/256, blue: 116/256))
                .frame(width: 12, height: 12)
        }
    }
}

struct PressButton<Label>: View where Label: View {
    @EnvironmentObject private var client: Client
    
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
            client.send("PRESS \(identifier)")
            haptic.impactOccurred(intensity: 1)
        }, onRelease: {
            client.send("RELEASE \(identifier)")
            haptic.impactOccurred(intensity: 0.4)
        })
    }
}

private var grayColor = Color(red: 221/256, green: 218/256, blue: 231/256)

struct ContentView: View {
    @EnvironmentObject private var client: Client
    @Binding var shouldAutoReconnect: Bool
    @State private var hostCode: String = ""
    @State private var error: Error? = nil
    @State private var clientConnectionCancellable: AnyCancellable? = nil
    @State private var clientDisconnectionCancellable: AnyCancellable? = nil
    @State private var choosingConnection = false
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .center) {
                    Joystick(
                        identifier: "MAIN",
                        color: Color(red: 221/256, green: 218/256, blue: 231/256),
                        diameter: 150,
                        knobDiameter: 110,
                        label: Image(systemName: "target")
                            .resizable()
                            .frame(width: 95, height: 95)
                            .foregroundColor(.black.opacity(0.2)),
                        hapticsSharpness: 0.8
                    )
                    
                    Spacer()
                    
                    ZStack {
                        PressButton(label: Image(systemName: "arrowtriangle.up.fill"), identifier: "D_UP")
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*1.5, y: 42*0.5)
                        PressButton(label: Image(systemName: "arrowtriangle.down.fill"), identifier: "D_DOWN")
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*1.5, y: 42*2.5)
                        PressButton(label: Image(systemName: "arrowtriangle.left.fill"), identifier: "D_LEFT")
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*0.5, y: 42*1.5)
                        PressButton(label: Image(systemName: "arrowtriangle.right.fill"), identifier: "D_RIGHT")
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*2.5, y: 42*1.5)
                    }
                    .frame(width: 42*3, height: 42*3)
                }
                .frame(width: 200)
                
                Spacer()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        HStack {
                            PressButton(label: Text("L"), identifier: "L")
                                .buttonStyle(GCCButton(
                                    color: grayColor,
                                    width: 100,
                                    height: 42,
                                    shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                                ))
                            Spacer()
                            PressButton(label: Text("R"), identifier: "R")
                                .buttonStyle(GCCButton(
                                    color: grayColor,
                                    width: 100,
                                    height: 42,
                                    shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                                ))
                        }
                        PressButton(label: Text("Z"), identifier: "Z")
                            .buttonStyle(GCCButton(
                                color: Color(red: 72/256, green: 100/256, blue: 226/256),
                                width: 100,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                            ))
                    }
                        .frame(
                          minWidth: 0,
                          maxWidth: .infinity,
                          alignment: .center
                        )
                    
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 20) {
                        Light(on: client.controllerIndex == 0)
                        Light(on: client.controllerIndex == 1)
                        Light(on: client.controllerIndex == 2)
                        Light(on: client.controllerIndex == 3)
                    }
                    
                    Spacer()
                    
                    PressButton(label: Text(""), identifier: "START")
                        .buttonStyle(GCCButton(
                            color: grayColor,
                            width: 34,
                            height: 34,
                            shape: Circle()
                        ))
                    
                    Spacer()
                    
                    if self.client.connection == nil {
                        HStack {
                            if self.client.hasLastServer {
                                Button("Reconnect") {
                                    self.client.reconnect()
                                }
                                .buttonStyle(GCCButton(
                                    color: grayColor,
                                    shape: Capsule(style: .continuous)
                                ))
                            }
                            Button(self.client.hasLastServer ? "New" : "Connect") {
                                self.choosingConnection = true
                            }
                                .buttonStyle(GCCButton(
                                    color: grayColor,
                                    shape: Capsule(style: .continuous)
                                ))
                        }
                    } else {
                        Button("Disconnect") {
                            self.shouldAutoReconnect = false
                            self.client.disconnect()
                        }
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                shape: Capsule(style: .continuous)
                            ))
                    }
                }
                
                Spacer()

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
                            .offset(x: 0, y: 60 + 12 + 30)
                            .rotationEffect(.degrees(60))
                        PressButton(label: Text("Y"), identifier: "Y")
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                width: 80,
                                height: 42,
                                shape: Capsule(style: .continuous)
                            ))
                            .offset(x: 0, y: 60 + 12 + 21)
                            .rotationEffect(.degrees(175))
                        PressButton(label: Text("X"), identifier: "X")
                            .buttonStyle(GCCButton(
                                color: grayColor,
                                width: 80,
                                height: 42,
                                shape: Capsule(style: .continuous)
                            ))
                            .offset(x: 0, y: 60 + 12 + 21)
                            .rotationEffect(.degrees(260))
                    }
                        .offset(y: 20)
                        .frame(height: 120 + 60)
                    
                    Spacer()
                    
                    Joystick(
                        identifier: "C",
                        color: Color(red: 254/256, green: 217/256, blue: 39/256),
                        diameter: 150,
                        knobDiameter: 80,
                        label: Text("C")
                            .foregroundColor(.black.opacity(0.2))
                            .font(.gameCubeController),
                        hapticsSharpness: 0.8
                    )
                }
                .frame(width: 200)
            }
        }
            .padding()
            .frame(
              minWidth: 0,
              maxWidth: .infinity,
              minHeight: 0,
              maxHeight: .infinity,
              alignment: .center
            )
            .sheet(isPresented: $choosingConnection) {
                ServerBrowserView(shown: $choosingConnection) { endpoint in
                    self.client.connect(to: endpoint)
                    self.shouldAutoReconnect = true
                }
            }
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
