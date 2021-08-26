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

struct ContentView: View {
    @EnvironmentObject private var client: Client
    @Binding var shouldAutoReconnect: Bool
    @State private var hostCode: String = ""
    @State private var error: Error? = nil
    @State private var errorStr: String? = nil
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
                                color: GameCubeColors.lightGray,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*1.5, y: 42*0.5)
                        PressButton(label: Image(systemName: "arrowtriangle.down.fill"), identifier: "D_DOWN")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*1.5, y: 42*2.5)
                        PressButton(label: Image(systemName: "arrowtriangle.left.fill"), identifier: "D_LEFT")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
                                width: 42,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4)
                            ))
                            .position(x: 42*0.5, y: 42*1.5)
                        PressButton(label: Image(systemName: "arrowtriangle.right.fill"), identifier: "D_RIGHT")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
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
                                    color: GameCubeColors.lightGray,
                                    width: 100,
                                    height: 42,
                                    shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                                ))
                            Spacer()
                            PressButton(label: Text("R"), identifier: "R")
                                .buttonStyle(GCCButton(
                                    color: GameCubeColors.lightGray,
                                    width: 100,
                                    height: 42,
                                    shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                                ))
                        }
                        PressButton(label: Text("Z"), identifier: "Z")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.zColor,
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
                    
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(0..<Int(AvailableControllers.numberOfControllers)) { (i: Int) in
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
                    }
                    
                    Spacer()
                    
                    PressButton(label: Text(""), identifier: "START")
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 34,
                            height: 34,
                            shape: Circle()
                        ))
                    
                    Spacer()
                    
                    if self.client.connection == nil {
                        HStack {
                            if self.client.hasLastServer {
                                Button("Rejoin") {
                                    self.client.reconnect()
                                }
                                    .buttonStyle(GCCButton(
                                        color: GameCubeColors.lightGray,
                                        shape: Capsule(style: .continuous)
                                    ))
                            }
                            Button("Join") {
                                self.choosingConnection = true
                            }
                                .buttonStyle(GCCButton(
                                    color: GameCubeColors.lightGray,
                                    shape: Capsule(style: .continuous)
                                ))
                        }
                    } else {
                        Button("Leave") {
                            self.shouldAutoReconnect = false
                            self.client.disconnect()
                        }
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
                                shape: Capsule(style: .continuous)
                            ))
                    }
                }
                
                Spacer()

                VStack {
                    ZStack {
                        PressButton(label: Text("A"), identifier: "A")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.green,
                                width: 120,
                                height: 120
                            ))
                        PressButton(label: Text("B").rotationEffect(.degrees(-60)), identifier: "B")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.red,
                                width: 60,
                                height: 60
                            ))
                            .offset(x: 0, y: 60 + 12 + 30)
                            .rotationEffect(.degrees(60))
                        PressButton(label: Text("Y").rotationEffect(.degrees(-175)), identifier: "Y")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
                                width: 80,
                                height: 42,
                                shape: Capsule(style: .continuous)
                            ))
                            .offset(x: 0, y: 60 + 12 + 21)
                            .rotationEffect(.degrees(175))
                        PressButton(label: Text("X").rotationEffect(.degrees(-260)), identifier: "X")
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
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
                        color: GameCubeColors.yellow,
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
            .onReceive(client.errorPublisher, perform: { error in
                self.error = error
            })
            .sheet(isPresented: $choosingConnection) {
                ServerBrowserView { endpoint in
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
