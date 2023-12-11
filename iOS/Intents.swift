import AppIntents
import UIKit

let AIntentNotificationName = Notification.Name(rawValue: "PressAIntent")

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PressAIntent: AppIntent {
    
    static var title: LocalizedStringResource = "A Button"
    static var description = IntentDescription("Press the A Button")
    static var isDiscoverable = false
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: AIntentNotificationName, object: nil)
        }
        return .result()
    }
}

let BIntentNotificationName = Notification.Name(rawValue: "PressBIntent")

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PressBIntent: AppIntent {
    
    static var title: LocalizedStringResource = "B Button"
    static var description = IntentDescription("Press the B Button")
    static var isDiscoverable = false
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: BIntentNotificationName, object: nil)
        }
        return .result()
    }
}
