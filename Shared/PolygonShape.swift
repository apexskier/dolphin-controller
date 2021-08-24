import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-polygons-and-stars

struct Polygon: Shape {
    let corners: Int

    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        var currentAngle = -CGFloat.pi / 2
        let angleAdjustment = .pi * 2 / CGFloat(corners)

        var path = Path()
        path.move(to: CGPoint(x: center.x * cos(currentAngle), y: center.y * sin(currentAngle)))

        // track the lowest point we draw to, so we can center later
        var bottomEdge: CGFloat = 0

        for _ in 0..<corners  {
            let sinAngle = sin(currentAngle)
            let cosAngle = cos(currentAngle)
            let bottom: CGFloat

            bottom = center.y * sinAngle

            path.addLine(to: CGPoint(x: center.x * cosAngle, y: bottom))

            if bottom > bottomEdge {
                bottomEdge = bottom
            }

            currentAngle += angleAdjustment
        }

        let unusedSpace = (rect.height / 2 - bottomEdge) / 2

        let transform = CGAffineTransform(translationX: center.x, y: center.y + unusedSpace)
        return path.applying(transform)
    }
}
