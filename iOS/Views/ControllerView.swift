import SwiftUI

private struct PressButton<Label>: View where Label: View {
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

private struct MainJoystickRidge: View {
    var width: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let minDimension = min(geometry.size.height, geometry.size.width)
            ZStack {
                Circle().foregroundColor(GameCubeColors.lightGray)
                RadialGradient(
                    stops: [
                        Gradient.Stop(color: Color(white: 0.1), location: 0),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.10),
                        Gradient.Stop(color: Color(white: 0.7), location: 0.15),
                        Gradient.Stop(color: Color(white: 0.7), location: 0.15),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.3),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.7),
                        Gradient.Stop(color: Color(white: 0.7), location: 0.85),
                        Gradient.Stop(color: Color(white: 0.5), location: 0.90),
                        Gradient.Stop(color: Color(white: 0.1), location: 1),
                    ],
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
    var playerIndicators: PlayerIndicators
    var appButtons: AppButtons

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

                playerIndicators

                Spacer()

                VStack(spacing: 4) {
                    Text("START/PAUSE").gcLabel(size: 16)
                    PressButton(label: Text(""), identifier: "START")
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
                    PressButton(label: Text("A"), identifier: "A")
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.green,
                            width: 120,
                            height: 120
                        ))
                    PressButton(label: Text("B").rotationEffect(.degrees(-60)), identifier: "B")
                        .offset(x: 0, y: 60 + 12 + 30)
                        .rotationEffect(.degrees(60))
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.red,
                            width: 60,
                            height: 60
                        ))
                    PressButton(label: Text("Y").rotationEffect(.degrees(-175)), identifier: "Y")
                        .offset(x: 0, y: 60 + 12 + 21)
                        .rotationEffect(.degrees(175))
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.lightGray,
                            width: 80,
                            height: 42,
                            shape: Capsule(style: .continuous)
                        ))
                    PressButton(label: Text("X").rotationEffect(.degrees(-260)), identifier: "X")
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
                )
            }
            .frame(width: 200)
        }
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        ControllerView(playerIndicators: EmptyView(), appButtons: EmptyView())
    }
}
