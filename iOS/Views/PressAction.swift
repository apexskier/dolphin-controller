import SwiftUI

struct PressActions: ViewModifier {
    @Binding var pressed: Bool
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ test in
                        if !pressed {
                            onPress()
                            pressed = true
                        }
                    })
                    .onEnded({ _ in
                        onRelease()
                        pressed = false
                    })
            )
    }
}

extension View {
    func pressAction(pressed: Binding<Bool>, onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(pressed: pressed, onPress: {
            onPress()
        }, onRelease: {
            onRelease()
        }))
    }
}
