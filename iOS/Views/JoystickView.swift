import SwiftUI
import CoreHaptics

// this avoids reinitializing the haptics object during the view's init
private class HapticContainer: ObservableObject {
    private let sharpness: Float

    init(sharpness: Float) {
        self.sharpness = sharpness
    }

    lazy var haptics = Haptics(sharpness: sharpness)
}

struct Joystick<Label>: View where Label: View {
    @EnvironmentObject var client: Client
    
    var identifier: String
    var color: Color
    var diameter: CGFloat
    var knobDiameter: CGFloat
    var label: Label
    
    private var handleChange: (CGPoint) -> Void

    private let pressHaptic = UIImpactFeedbackGenerator(style: .rigid)
    @State private var hapticContainer: HapticContainer

    @AppStorage("joystickHapticsEnabled") private var joystickHapticsEnabled = true

    init(
        identifier: String,
        color: Color,
        diameter: CGFloat,
        knobDiameter: CGFloat,
        label: Label,
        hapticsSharpness: Float,
        handleChange: @escaping (CGPoint) -> Void
    ) {
        self.identifier = identifier
        self.color = color
        self.diameter = diameter
        self.knobDiameter = knobDiameter
        self.label = label
        self._hapticContainer = .init(initialValue: HapticContainer(sharpness: hapticsSharpness))
        self.handleChange = handleChange
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
                self.handleChange(CGPoint(x: 0.5, y: 0.5))
                client.send("SET \(identifier) 0.5 0.5")
                inCenter = true
                hapticContainer.haptics.stop()
                return
            }
            
            if dragValue == nil {
                hapticContainer.haptics.start()
                pressHaptic.impactOccurred()
            }
            
            let translation = value.translation
            let x = (translation.width / (diameter*1.5)).clamped(to: -0.5...0.5)
            let y = (-translation.height / (diameter*1.5)).clamped(to: -0.5...0.5)
            self.handleChange(CGPoint(x: x+0.5, y: y+0.5))
            client.send("SET \(identifier) \(x+0.5) \(y+0.5)")
            let magnitude = sqrt(x*2*x*2 + y*2*y*2)
            inCenter = magnitude < 0.2
            outsideEdges = magnitude > 1
            
            hapticContainer.haptics.setIntensity(magnitude)
        }
    }
    
    private var knob: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: knobDiameter, height: knobDiameter)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            label
        }
        .allowsHitTesting(false)
    }

    private var transparentColor: Color {
        color.opacity(0.2)
    }
    
    private var target: some View {
        Polygon(corners: 8)
            .fill(transparentColor)
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
                            .fill(transparentColor)
                            .frame(width: diameter*1.3, height: diameter*1.3)
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
        .onAppear(perform: {
            self.hapticContainer.haptics.enabled = self.joystickHapticsEnabled
        })
        .onChange(of: joystickHapticsEnabled) { newValue in
            self.hapticContainer.haptics.enabled = newValue
        }
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
