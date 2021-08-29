import SwiftUI

final class GameCubeColors {
    static let lightGray = Color(red: 221/256, green: 218/256, blue: 231/256)
    static let zColor = Color(red: 72/256, green: 100/256, blue: 226/256)
    static let green = Color(red: 55/256, green: 199/256, blue: 195/256)
    static let red = Color(red: 232/256, green: 16/256, blue: 39/256)
    static let yellow = Color(red: 254/256, green: 217/256, blue: 39/256)
    static let purple = Color(red: 106/256, green: 115/256, blue: 188/256)
}

extension Font {
    // https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9
    static func gameCubeController(size: CGFloat) -> Font {
        Self.custom("Futura-CondensedMedium", size: size)
    }
}

struct GCLabel: ViewModifier {
    var size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.gameCubeController(size: size))
            .foregroundColor(.black.opacity(0.25))
            .blendMode(.multiply)
    }
}

extension View {
    func gcLabel(size: CGFloat = 30) -> some View {
        modifier(GCLabel(size: size))
    }
}
