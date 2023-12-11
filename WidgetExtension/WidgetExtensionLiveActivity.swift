import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetExtensionLiveActivity: Widget {
    let aButton: some View = Button(intent: PressAIntent()) {
        Text("A")
    }
        .buttonStyle(GCCButton(
            color: GameCubeColors.green,
            width: 60,
            height: 60
        ))
    
    let bButton: some View = VStack {
        Spacer()
        Button(intent: PressBIntent()) {
            Text("B")
        }
            .buttonStyle(GCCButton(
                color: GameCubeColors.red,
                width: 50,
                height: 50
            ))
    }.frame(maxHeight: .infinity)
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                VStack {
                    Spacer()
                    bButton
                }.frame(maxHeight: .infinity)
                Spacer()
                Text("P\(context.state.slot+1)")
                    .gcLabel(size: 20)
                Spacer()
                aButton
            }
            .frame(maxWidth: .infinity)
            .padding()
            .activityBackgroundTint(GameCubeColors.purple)
            .activitySystemActionForegroundColor(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Spacer()
                        bButton
                    }.frame(maxHeight: .infinity)
                }
                DynamicIslandExpandedRegion(.center) {
                    SlotText(slot: context.state.slot)
                        .font(.gameCubeController(size: 24)).bold()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    aButton
                }
            } compactLeading: {
                SlotText(slot: context.state.slot)
                    .font(.gameCubeController(size: 16)).bold()
            } compactTrailing: {
                // nothing
            } minimal: {
                SlotText(slot: context.state.slot)
                    .font(.gameCubeController(size: 16)).bold()
            }
            .keylineTint(GameCubeColors.purple)
        }
    }
}

struct SlotText: View {
    var slot: UInt8
    
    var body: some View {
        Text("P\(slot+1)")
    }
}

#Preview("Notification", as: .content, using: WidgetExtensionAttributes()) {
    WidgetExtensionLiveActivity()
} contentStates: {
    WidgetExtensionAttributes.ContentState(slot: 1)
}
