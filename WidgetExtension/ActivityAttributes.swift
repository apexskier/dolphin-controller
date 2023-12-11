import ActivityKit

struct WidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var slot: UInt8
    }
}
