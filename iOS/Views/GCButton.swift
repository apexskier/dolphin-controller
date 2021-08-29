import SwiftUI

struct GCCButton<S>: ButtonStyle where S: Shape {
    var color: Color
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var shape: S
    var fontSize: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .gcLabel(size: fontSize)
            .padding()
            .frame(width: width, height: height)
            .background(color)
            .clipShape(shape)
            .brightness(configuration.isPressed ? -0.1 : 0)
    }
}

extension GCCButton where S == Circle {
    init(color: Color, width: CGFloat = 42, height: CGFloat = 42, fontSize: CGFloat = 30) {
        self.init(color: color, width: width, height: height, shape: Circle(), fontSize: fontSize)
    }
}
