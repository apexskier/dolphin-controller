import ActivityKit

@available(iOS 16.2, *)
class ActivityManager {
    static var activity: Activity<iOSWidgetExtensionAttributes>? = nil
    
    static func update(slot: UInt8?) async {
        if let slot = slot {
            let content = ActivityContent(state: iOSWidgetExtensionAttributes.ContentState(slot: slot), staleDate: nil)
            if let activeActivity = self.activity {
                await activeActivity.update(content)
            } else {
                do {
                    Self.activity = try Activity.request(attributes: iOSWidgetExtensionAttributes(), content: content)
                } catch {
                    print("error: \(error)")
                }
            }
        } else {
            await Self.activity?.end(nil, dismissalPolicy: .immediate)
            Self.activity = nil
        }
    }
}
