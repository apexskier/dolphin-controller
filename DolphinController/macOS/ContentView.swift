import SwiftUI

struct ControllerDots: View {
    var number: Int
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<number) { _ in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 4, height: 4)
            }
        }
            .accessibility(label: Text("Controller \(number)"))
    }
}

let dotVerticalSpace: CGFloat = 16

struct ControllerPlug: View {
    var number: Int
    var connected: Bool
    
    var body: some View {
        VStack(spacing: dotVerticalSpace) {
            ControllerDots(number: number)
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

struct PlugShape: Shape {
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

struct FaceplateShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            
            let inset: CGFloat = width * 0.01
            
            path.move(to: CGPoint(x: inset, y: 0))
            path.addLine(to: CGPoint(x: width - inset, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: width - inset, y: height),
                control: CGPoint(x: width + inset, y: height / 2)
            )
            path.addLine(to: CGPoint(x: inset, y: height))
            path.addQuadCurve(
                to: CGPoint(x: inset, y: 0),
                control: CGPoint(x: -inset, y: height / 2)
            )
            
            path.closeSubpath()
        }
    }
}

struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        Path { path in
            let w = rect.width
            let h = rect.height

            // Make sure we do not exceed the size of the rectangle
            let tr = min(min(self.tr, h/2), w/2)
            let tl = min(min(self.tl, h/2), w/2)
            let bl = min(min(self.bl, h/2), w/2)
            let br = min(min(self.br, h/2), w/2)

            path.move(to: CGPoint(x: w / 2.0, y: 0))
            path.addLine(to: CGPoint(x: w - tr, y: 0))
            path.addArc(
                center: CGPoint(x: w - tr, y: tr),
                radius: tr,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: w, y: h - br))
            path.addArc(
                center: CGPoint(x: w - br, y: h - br),
                radius: br,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: bl, y: h))
            path.addArc(
                center: CGPoint(x: bl, y: h - bl),
                radius: bl,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: 0, y: tl))
            path.addArc(
                center: CGPoint(x: tl, y: tl),
                radius: tl,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
            path.closeSubpath()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var server: Server
    
    var connectedControllerCount: Int {
        server.controllers
            .compactMap({ $0.value })
            .count
    }
    
    var body: some View {
        VStack {
            Spacer(minLength: 0)
            Text("Connect to\n“\(server.name)”")
                .multilineTextAlignment(.center)
                .fixedSize()
            Spacer(minLength: 16)
            HStack(spacing: 30) {
                ForEach(0..<server.controllerCount) { i in
                    ControllerPlug(number: i+1, connected: server.controllers[i] != nil)
                }
            }
                .padding(EdgeInsets(top: dotVerticalSpace, leading: 24, bottom: 20, trailing: 24))
                // background, not clipshape, to not obscure cord
                .background(FaceplateShape().fill(GameCubeColors.lightGray))
            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle(Text(server.name))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
