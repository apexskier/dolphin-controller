import SwiftUI

let dotVerticalSpace: CGFloat = 16

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
                ForEach(0..<Int(AvailableControllers.numberOfControllers)) { (i: Int) in
                    ControllerPlugView(index: UInt8(i), connected: server.controllers[UInt8(i)] != nil)
                        .accessibilityLabel("Tap to disconnect controller \(i+1)")
                        .onTapGesture {
                            server.controllers[UInt8(i)]??.connection.cancel()
                        }
                }
            }
                .padding(EdgeInsets(top: dotVerticalSpace, leading: 24, bottom: 20, trailing: 24))
                // background, not clipshape, to not obscure cord
                .background(FaceplateShape().fill(GameCubeColors.lightGray))
            Spacer(minLength: 0)
        }
        .navigationTitle(Text(server.name))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
