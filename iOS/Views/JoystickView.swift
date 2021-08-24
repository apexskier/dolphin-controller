import SwiftUI
import CoreHaptics

struct Joystick<Label>: View where Label: View {
    @EnvironmentObject var client: Client
    
    var identifier: String
    var color: Color
    var diameter: CGFloat
    var knobDiameter: CGFloat
    var label: Label
    var hapticsSharpness: Float
    
    private let pressHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let haptics: Haptics
    
    init(
        identifier: String,
        color: Color,
        diameter: CGFloat,
        knobDiameter: CGFloat,
        label: Label,
        hapticsSharpness: Float
    ) {
        self.identifier = identifier
        self.color = color
        self.diameter = diameter
        self.knobDiameter = knobDiameter
        self.label = label
        self.hapticsSharpness = hapticsSharpness
        
        self.haptics = Haptics(sharpness: hapticsSharpness)
    }
    
    @State private var inCenter: Bool = true {
        willSet {
            if inCenter != newValue {
                if newValue {
                    pressHaptic.impactOccurred(intensity: 0.6)
                } else {
                    pressHaptic.impactOccurred(intensity: 0.3)
                }
            }
        }
    }
    @State private var outsideEdges: Bool = false {
        willSet {
            if newValue {
                if !outsideEdges {
                    pressHaptic.impactOccurred(intensity: 0.8)
                }
            }
        }
    }
    @State private var dragValue: DragGesture.Value? = nil {
        willSet {
            guard let value = newValue else {
                client.send("SET \(identifier) 0.5 0.5")
                inCenter = true
                haptics.stop()
                return
            }
            
            if dragValue == nil {
                haptics.start()
                pressHaptic.impactOccurred()
            }
            
            let translation = value.translation
            let x = (translation.width / (diameter*1.5)).clamped(to: -0.5...0.5)
            let y = (-translation.height / (diameter*1.5)).clamped(to: -0.5...0.5)
            client.send("SET \(identifier) \(x+0.5) \(y+0.5)")
            let magnitude = sqrt(x*2*x*2 + y*2*y*2)
            inCenter = magnitude < 0.2
            outsideEdges = magnitude > 1
            
            haptics.setIntensity(magnitude)
        }
    }
    
    private var knob: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: knobDiameter, height: knobDiameter)
            label
        }
        .allowsHitTesting(false)
    }
    
    private var target: some View {
        Polygon(corners: 8)
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
                            self.pressHaptic.prepare()
                        })
                        .onEnded({ value in
                            self.dragValue = nil
                        })
                )
            ZStack {
                if let dragValue = self.dragValue {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: diameter*1.5, height: diameter*1.5)
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
        let r = (diameter*1.5)/2
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
