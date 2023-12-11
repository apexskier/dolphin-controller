import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                Button(intent: PressBIntent()) {
                    Text("B")
                }
                    .buttonStyle(GCCButton(
                        color: GameCubeColors.red,
                        width: 50,
                        height: 50
                    ))
                Spacer()
                Text("P\(context.state.slot+1)")
                    .gcLabel(size: 20)
                Spacer()
                Button(intent: PressAIntent()) {
                    Text("A")
                }
                    .buttonStyle(GCCButton(
                        color: GameCubeColors.green,
                        width: 60,
                        height: 60
                    ))
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
                        Button(intent: PressBIntent()) {
                            Text("B")
                        }
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.red,
                            width: 60,
                            height: 60
                        ))
                    }.frame(maxHeight: .infinity)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("P\(context.state.slot+1)")
                        .font(.gameCubeController(size: 24))
                        .bold()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // might be nice to be able to confirm without opening the app in something like mario party
                    Button(intent: PressBIntent()) {
                        Text("A")
                    }
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.green,
                            width: 80,
                            height: 80
                        ))
                }
            } compactLeading: {
                Text("P\(context.state.slot+1)")
                    .font(.gameCubeController(size: 16))
                    .bold()
            } compactTrailing: {
                // nothing
            } minimal: {
                Text("P\(context.state.slot+1)")
                    .font(.gameCubeController(size: 16))
                    .bold()
            }
            .keylineTint(GameCubeColors.purple)
        }
    }
}

#Preview("Notification", as: .content, using: WidgetExtensionAttributes()) {
    WidgetExtensionLiveActivity()
} contentStates: {
    WidgetExtensionAttributes.ContentState(slot: 1)
}
