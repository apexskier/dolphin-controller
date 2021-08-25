import SwiftUI

private struct ControllerDots: View {
    var index: UInt8

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<Int(index+1)) { _ in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 4, height: 4)
            }
        }
            .accessibility(label: Text("Controller \(index+1)"))
    }
}

private struct PlugShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.addArc(
                center: CGPoint(x: width * 0.5, y: height * 0.5),
                radius: width * 0.5,
                startAngle: .degrees(-50 - 90),
                endAngle: .degrees(50 - 90),
                clockwise: true
            )
            path.closeSubpath()
        }
    }
}

struct ControllerPlugView: View {
    var index: UInt8
    var connected: Bool

    var body: some View {
        VStack(spacing: dotVerticalSpace) {
            ControllerDots(index: index)
            ZStack {
                Circle()
                    .fill(Color(white: 0.3))
                    .frame(width: 36, height: 36)
                if connected {
                    Circle()
                        .fill(GameCubeColors.purple)
                        .frame(width: 30, height: 30)
                    ZStack { // this pulls the "cord" (rounded rect) out of the layout flow
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.2))
                            .frame(width: 12, height: 2000) // I could probably do something fancy with a geometry reader and passing properties through whatever that thing is to automatically make this the size of the window but this should be fine
                            .offset(x: 0, y: 1000 - 6)
                    }
                    .frame(width: 30, height: 30)
                } else {
                    PlugShape()
                        .fill(Color.black)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

struct ControllerPlugView_Previews: PreviewProvider {
    static var previews: some View {
        ControllerPlugView(index: 1, connected: true)
    }
}
