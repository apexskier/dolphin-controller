import SwiftUI

extension Font {
    // https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9
    static func gameCubeController(size: CGFloat = 30) -> Font {
        Self.custom("Futura-CondensedMedium", size: size)
    }
}

struct GCCButton<S>: ButtonStyle where S: Shape {
    var color: Color
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var shape: S
    var fontSize: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: width, height: height)
            .background(color)
            .foregroundColor(.black.opacity(0.2))
            .font(.gameCubeController(size: fontSize))
            .clipShape(shape)
            .brightness(configuration.isPressed ? -0.1 : 0)
    }
}

extension GCCButton where S == Circle {
    init(color: Color, width: CGFloat = 42, height: CGFloat = 42, fontSize: CGFloat = 30) {
        self.init(color: color, width: width, height: height, shape: Circle(), fontSize: fontSize)
    }
}
