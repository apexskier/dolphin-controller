import ActivityKit

struct iOSWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var slot: UInt8
    }
}
