import SwiftUI

struct Joystick<Label>: View where Label: View {
    @EnvironmentObject var client: Client
    
    var identifier: String
    var color: Color
    var diameter: CGFloat
    var knobDiameter: CGFloat = 50
    var label: Label
    
    private let edgeHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let pressHaptic = UIImpactFeedbackGenerator(style: .rigid)
    
    @State private var dragValue: DragGesture.Value? = nil {
        willSet {
            guard let value = newValue else {
                client.send("SET \(identifier) 0.5 0.5")
                return
            }
            
            if dragValue == nil {
                pressHaptic.impactOccurred()
            }
            
            let translation = value.translation
            let x = (translation.width / diameter).clamped(to: -0.5...0.5)
            let y = (-translation.height / diameter).clamped(to: -0.5...0.5)
            client.send("SET \(identifier) \(x+0.5) \(y+0.5)")
            let intensity = sqrt(x*2*x*2 + y*2*y*2)
            if (intensity > 1) {
                edgeHaptic.impactOccurred()
            }
        }
    }
    
    private var knob: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: knobDiameter, height: knobDiameter)
            label
        }
        .allowsHitTesting(false)
    }
    
    private var target: some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: diameter, height: diameter)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            target
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            self.dragValue = value
                        })
                        .onEnded({ value in
                            self.dragValue = nil
                        })
                )
            ZStack {
                if let dragValue = self.dragValue {
                    ZStack {
                        target
                        knob
                    }
                        .position(
                            x: dragValue.startLocation.x,
                            y: dragValue.startLocation.y
                        )
                    draggedKnob(drag: dragValue)
                } else {
                    knob
                }
            }
            .allowsHitTesting(false)
        }
        .frame(width: diameter, height: diameter) // ensure layout shifting won't happen when dragging
    }
    
    private func draggedKnob(drag: DragGesture.Value) -> some View {
        // limit position of knob to outer edges of valid position
        var x = drag.translation.width
        var y = drag.translation.height
        let magnitude = sqrt(x*x + y*y)
        let r = diameter/2
        if magnitude > r {
            x = (x / magnitude) * r
            y = (y / magnitude) * r
        }
        return knob
            .position(
                x: drag.startLocation.x + x,
                y: drag.startLocation.y + y
            )
    }
}
