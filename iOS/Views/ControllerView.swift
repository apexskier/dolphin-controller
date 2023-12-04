import SwiftUI

private struct PressButton<Label>: View where Label: View {
    @EnvironmentObject private var client: Client

    private let haptic = UIImpactFeedbackGenerator(style: .rigid)
    var label: Label
    var identifier: String
    @Binding var pressed: Bool

    var body: some View {
        Button {
            // no direct tap action
        } label: {
            label
        }
        .pressAction(pressed: $pressed, onPress: {
            client.send("PRESS \(identifier)")
            haptic.impactOccurred(intensity: 1)
        }, onRelease: {
            client.send("RELEASE \(identifier)")
            haptic.impactOccurred(intensity: 0.4)
        })
    }
}

private struct MainJoystickRidge: View {
    var width: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let minDimension = min(geometry.size.height, geometry.size.width)
            ZStack {
                Circle().foregroundColor(GameCubeColors.lightGray)
                RadialGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: Color(white: 0.1), location: 0),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.10),
                        Gradient.Stop(color: Color(white: 0.7), location: 0.15),
                        Gradient.Stop(color: Color(white: 0.7), location: 0.15),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.3),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.7),
                        Gradient.Stop(color: Color(white: 0.7), location: 0.85),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.90),
                        Gradient.Stop(color: Color(white: 0.1), location: 1),
                    ]),
                    center: .center,
                    startRadius: (minDimension / 2) - width,
                    endRadius: minDimension / 2
                )
                    .blendMode(.overlay)
            }
                .mask(Circle().strokeBorder(lineWidth: width))
                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
        }
    }
}

struct ControllerView<PlayerIndicators, AppButtons>: View where PlayerIndicators: View, AppButtons: View {
    @EnvironmentObject private var client: Client
    
    var playerIndicators: PlayerIndicators
    var appButtons: AppButtons
    
    @State var dUpPressed = false
    @State var dDownPressed = false
    @State var dLeftPressed = false
    @State var dRightPressed = false
    @State var lPressed = false
    @State var rPressed = false
    @State var zPressed = false
    @State var startPressed = false
    @State var aPressed = false
    @State var bPressed = false
    @State var xPressed = false
    @State var yPressed = false
    @State var mainJoystickValue = CGPoint(x: 0.5, y: 0.5)
    @State var cJoystickValue = CGPoint(x: 0.5, y: 0.5)
    
    @State var packetNumber: UInt32 = 0

    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Joystick(
                    identifier: "MAIN",
                    color: Color(red: 221/256, green: 218/256, blue: 231/256),
                    diameter: 150,
                    knobDiameter: 110,
                    label: ZStack {
                        MainJoystickRidge()
                            .frame(width: 30, height: 30)
                        MainJoystickRidge()
                            .frame(width: 60, height: 60)
                        MainJoystickRidge()
                            .frame(width: 90, height: 90)
                    },
                    hapticsSharpness: 0.8
                ) { point in
                    mainJoystickValue = point
                }

                Spacer()

                ZStack {
                    PressButton(label: Image(systemName: "arrowtriangle.up.fill"), identifier: "D_UP", pressed: $dUpPressed)
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 42,
                            height: 42,
                            shape: RoundedRectangle(cornerRadius: 4)
                        ))
                        .position(x: 42*1.5, y: 42*0.5)
                    PressButton(label: Image(systemName: "arrowtriangle.down.fill"), identifier: "D_DOWN", pressed: $dDownPressed)
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 42,
                            height: 42,
                            shape: RoundedRectangle(cornerRadius: 4)
                        ))
                        .position(x: 42*1.5, y: 42*2.5)
                    PressButton(label: Image(systemName: "arrowtriangle.left.fill"), identifier: "D_LEFT", pressed: $dLeftPressed)
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 42,
                            height: 42,
                            shape: RoundedRectangle(cornerRadius: 4)
                        ))
                        .position(x: 42*0.5, y: 42*1.5)
                    PressButton(label: Image(systemName: "arrowtriangle.right.fill"), identifier: "D_RIGHT", pressed: $dRightPressed)
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
                        PressButton(label: Text("L"), identifier: "L", pressed: $lPressed)
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
                                width: 100,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                            ))
                        Spacer()
                        PressButton(label: Text("R"), identifier: "R", pressed: $rPressed)
                            .buttonStyle(GCCButton(
                                color: GameCubeColors.lightGray,
                                width: 100,
                                height: 42,
                                shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
                            ))
                    }
                    PressButton(label: Text("Z"), identifier: "Z", pressed: $zPressed)
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

                playerIndicators

                Spacer()

                VStack(spacing: 4) {
                    Text("START/PAUSE").gcLabel(size: 16)
                    PressButton(label: Text(""), identifier: "START", pressed: $startPressed)
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 34,
                            height: 34,
                            shape: Circle()
                        ))
                        .accessibilityLabel(Text("START/PAUSE"))
                }

                Spacer()

                appButtons
            }

            Spacer()

            VStack {
                ZStack {
                    PressButton(label: Text("A"), identifier: "A", pressed: $aPressed)
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.green,
                            width: 120,
                            height: 120
                        ))
                    PressButton(label: Text("B").rotationEffect(.degrees(-60)), identifier: "B", pressed: $bPressed)
                        .offset(x: 0, y: 60 + 12 + 30)
                        .rotationEffect(.degrees(60))
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.red,
                            width: 60,
                            height: 60
                        ))
                    PressButton(label: Text("Y").rotationEffect(.degrees(-175)), identifier: "Y", pressed: $yPressed)
                        .offset(x: 0, y: 60 + 12 + 21)
                        .rotationEffect(.degrees(175))
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 80,
                            height: 42,
                            shape: Capsule(style: .continuous)
                        ))
                    PressButton(label: Text("X").rotationEffect(.degrees(-260)), identifier: "X", pressed: $xPressed)
                        .offset(x: 0, y: 60 + 12 + 21)
                        .rotationEffect(.degrees(260))
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 80,
                            height: 42,
                            shape: Capsule(style: .continuous)
                        ))
                }
                .offset(y: 20)
                .frame(height: 120 + 60)

                Spacer()

                Joystick(
                    identifier: "C",
                    color: GameCubeColors.yellow,
                    diameter: 150,
                    knobDiameter: 80,
                    label: Text("C").gcLabel(),
                    hapticsSharpness: 0.8
                ) { point in
                    cJoystickValue = point
                }
            }
            .frame(width: 200)
        }
        .onChange(of: dUpPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: dDownPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: dLeftPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: dRightPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: lPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: rPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: zPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: startPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: aPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: bPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: xPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: yPressed) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: mainJoystickValue) { newValue in
            self.sendCemuUpdate()
        }
        .onChange(of: cJoystickValue) { newValue in
            self.sendCemuUpdate()
        }
    }
    
    func sendCemuUpdate() {
        var buttons1 = ButtonsMask1()
        var buttons2 = ButtonsMask2()
        
        if dUpPressed {
            buttons1.insert(.dPadUp)
        }
        if dDownPressed {
            buttons1.insert(.dPadDown)
        }
        if dLeftPressed {
            buttons1.insert(.dPadLeft)
        }
        if dRightPressed {
            buttons1.insert(.dPadRight)
        }
        if lPressed {
            buttons2.insert(.l1)
        }
        if rPressed {
            buttons2.insert(.r1)
        }
        if zPressed {
        }
        if startPressed {
            buttons1.insert(.options)
        }
        if aPressed {
            buttons2.insert(.a)
        }
        if bPressed {
            buttons2.insert(.b)
        }
        if xPressed {
            buttons2.insert(.x)
        }
        if yPressed {
            buttons2.insert(.y)
        }
        
        self.client.sendCemuhook(OutgoingControllerData(
            controllerData: .init(
                slot: 0,
                state: .connected,
                model: .notApplicable,
                connectionType: .notApplicable,
                batteryStatus: .notApplicable
            ),
            isConnected: true,
            clientPacketNumber: self.packetNumber,
            buttons1: buttons1,
            buttons2: buttons2,
            leftStickX: UInt8(mainJoystickValue.x * CGFloat(UInt8.max)),
            leftStickY: UInt8(mainJoystickValue.y * CGFloat(UInt8.max)),
            rightStickX: UInt8(cJoystickValue.x * CGFloat(UInt8.max)),
            rightStickY: UInt8(cJoystickValue.y * CGFloat(UInt8.max)),
            analogDPadLeft: 128,
            analogDPadDown: 128,
            analogDPadRight: 128,
            analogDPadUp: 128,
            analogY: 128,
            analogB: 128,
            analogA: 128,
            analogX: 128,
            analogR1: 128,
            analogL1: 128,
            analogR2: 128,
            analogL2: 128,
            firstTouch: TouchData(active: false, id: 0, xPos: 0, yPos: 0),
            secondTouch: TouchData(active: false, id: 0, xPos: 0, yPos: 0),
            motionTimestamp: 0,
            accX: 0,
            accY: 0,
            accZ: 0,
            gyroPitch: 0,
            gyroYaw: 0,
            gyroRoll: 0)
        )
        self.packetNumber += 1
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        ControllerView(
            playerIndicators: EmptyView(),
            appButtons: EmptyView(),
            dUpPressed: false,
            dDownPressed: false,
            dLeftPressed: false,
            dRightPressed: false,
            lPressed: false,
            rPressed: false,
            zPressed: false,
            startPressed: false,
            aPressed: false,
            bPressed: false,
            xPressed: false,
            yPressed: false
        )
    }
}
