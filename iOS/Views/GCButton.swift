import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

let buttonTexture: CIImage = {
    let colorNoise = CIFilter.randomGenerator()
    let grayscale = CIFilter.colorMonochrome()
    grayscale.inputImage = colorNoise.outputImage!
    let opacity = CIFilter.colorMatrix()
    opacity.inputImage = grayscale.outputImage!
    opacity.aVector = CIVector(x: 0, y: 0, z: 0, w: 0.1)
    return opacity.outputImage!
}()

// let blend = CIFilter.overlayBlendMode()
// blend.inputImage = buttonTexture
// blend.backgroundImage = CIImage(color: CIColor(cgColor: color.cgColor!))
// let image = blend.outputImage!

// let finalImage = image.cropped(to: CGRect(x: 0, y: 0, width: width ?? 1, height: height ?? 1))
// let cgImage = CIContext().createCGImage(finalImage, from: finalImage.extent)!

extension View {
    func innerShadow<S: Shape>(using shape: S, angle: Angle = .degrees(0), color: Color = .black, width: CGFloat = 6, blur: CGFloat = 6) -> some View {
        let finalX = CGFloat(cos(angle.radians - .pi / 2))
        let finalY = CGFloat(sin(angle.radians - .pi / 2))
        return self
            .overlay(
                shape
                    .stroke(color, lineWidth: width)
                    .offset(x: finalX * width * 0.6, y: finalY * width * 0.6)
                    .blur(radius: blur)
                    .mask(shape)
            )
    }
}

struct GCCButton<S>: ButtonStyle where S: Shape {
    var color: Color
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var shape: S
    var fontSize: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .gcLabel(size: fontSize)
            .padding()
            .frame(width: width, height: height)
            .background(color)
            .brightness(configuration.isPressed ? -0.075 : 0.001)
            .clipShape(shape)
            .contentShape(shape)
            .offset(x: 0, y: configuration.isPressed ? 1 : 0)
            .shadow(color: Color.black.opacity(0.3), radius: configuration.isPressed ? 1 : 2, x: 0, y: 1)
    }
}

extension GCCButton where S == Circle {
    init(color: Color, width: CGFloat = 42, height: CGFloat = 42, fontSize: CGFloat = 30) {
        self.init(color: color, width: width, height: height, shape: Circle(), fontSize: fontSize)
    }
}
