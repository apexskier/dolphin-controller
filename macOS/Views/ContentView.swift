import SwiftUI
import Foundation
import Combine

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
    @EnvironmentObject private var server: ControllerServer
    @State private var error: Error? = nil

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
                ForEach(0..<Int(AvailableControllers.numberOfControllers), id: \.self) { (i: Int) in
                    VStack {
                        ControllerPlugView(
                            index: UInt8(i),
                            connected: server.controllers[UInt8(i)] != nil
                        )
                            .help("Controller number \(dotsHelpFormatter.string(for: i+1) ?? "unknown")")
                            .accessibilityHint("Tap to disconnect controller \(i+1)")
                            .onTapGesture {
                                server.controllers[UInt8(i)]??.connection.cancel()
                            }
                            .onReceive(
                                server.controllers[UInt8(i)]??.errorPublisher
                                ?? PassthroughSubject(),
                                perform: { error in
                                    self.error = error
                                }
                            )
                    }
                }
            }
                .padding(EdgeInsets(top: dotVerticalSpace, leading: 24, bottom: 20, trailing: 24))
                // background, not clipshape, to not obscure cord
                .background(FaceplateShape().fill(GameCubeColors.lightGray))
            Spacer(minLength: 0)
        }
        .navigationTitle(Text(server.name))
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
        ContentView()
    }
}
