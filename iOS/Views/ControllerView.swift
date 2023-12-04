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
            haptic.impactOccurred(intensity: 1)
        }, onRelease: {
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
    
    @State private var packetNumber: UInt32 = 0
    @State private var batteryStatus: BatteryStatus = .notApplicable

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
        .onChange(of: dUpPressed, perform: sendCemuUpdate)
        .onChange(of: dDownPressed, perform: sendCemuUpdate)
        .onChange(of: dLeftPressed, perform: sendCemuUpdate)
        .onChange(of: dRightPressed, perform: sendCemuUpdate)
        .onChange(of: lPressed, perform: sendCemuUpdate)
        .onChange(of: rPressed, perform: sendCemuUpdate)
        .onChange(of: zPressed, perform: sendCemuUpdate)
        .onChange(of: startPressed, perform: sendCemuUpdate)
        .onChange(of: aPressed, perform: sendCemuUpdate)
        .onChange(of: bPressed, perform: sendCemuUpdate)
        .onChange(of: xPressed, perform: sendCemuUpdate)
        .onChange(of: yPressed, perform: sendCemuUpdate)
        .onChange(of: mainJoystickValue, perform: sendCemuUpdate)
        .onChange(of: cJoystickValue, perform: sendCemuUpdate)
        .onAppear(perform: {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBatteryStatus(0)
        })
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification), perform: updateBatteryStatus)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification), perform: updateBatteryStatus)
    }
                   
    func updateBatteryStatus(_: Any) {
        switch UIDevice.current.batteryState {
        case .charging:
            batteryStatus = .charging
        case .full:
            batteryStatus = .charged
        case .unknown:
            batteryStatus = .notApplicable
        case .unplugged:
            if UIDevice.current.batteryLevel > 0.95 {
                batteryStatus = .full
            } else if UIDevice.current.batteryLevel > 0.75 {
                batteryStatus = .high
            } else if UIDevice.current.batteryLevel > 0.40 {
                batteryStatus = .medium
            } else if UIDevice.current.batteryLevel > 0.15 {
                batteryStatus = .low
            } else {
                batteryStatus = .dying
            }
        @unknown default:
            batteryStatus = .notApplicable
        }
    }
    
    func sendCemuUpdate(_: Any) {
        guard let slot = client.controllerInfo?.assignedController else {
            return
        }
        
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
            buttons1.insert(.share)
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
        
        client.sendCemuhook(OutgoingControllerData(
            controllerData: .init(
                slot: slot,
                state: .connected, // TODO: use reserved if controller temporarily disconnects?
                model: .notApplicable,
                connectionType: .bluetooth,
                batteryStatus: batteryStatus
            ),
            isConnected: true,
            clientPacketNumber: packetNumber,
            buttons1: buttons1,
            buttons2: buttons2,
            leftStickX: UInt8(mainJoystickValue.x * CGFloat(UInt8.max)),
            leftStickY: UInt8(mainJoystickValue.y * CGFloat(UInt8.max)),
            rightStickX: UInt8(cJoystickValue.x * CGFloat(UInt8.max)),
            rightStickY: UInt8(cJoystickValue.y * CGFloat(UInt8.max)),
            analogDPadLeft: dLeftPressed ? .max : .min,
            analogDPadDown: dDownPressed ? .max : .min,
            analogDPadRight: dRightPressed ? .max : .min,
            analogDPadUp: dUpPressed ? .max : .min,
            analogY: yPressed ? .max : .min,
            analogB: bPressed ? .max : .min,
            analogA: aPressed ? .max : .min,
            analogX: xPressed ? .max : .min,
            analogR1: rPressed ? .max : .min,
            analogL1: lPressed ? .max : .min,
            analogR2: .min,
            analogL2: .min,
            firstTouch: TouchData(active: false, id: 0, xPos: 0, yPos: 0),
            secondTouch: TouchData(active: false, id: 0, xPos: 0, yPos: 0),
            motionTimestamp: 0,
            accX: 0,
            accY: 0,
            accZ: 0,
            gyroPitch: 0,
            gyroYaw: 0,
            gyroRoll: 0
        ))
        self.packetNumber += 1
    }
}

#Preview {
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
