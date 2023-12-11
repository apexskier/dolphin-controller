import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dolphin Ctrl"
    static var description = IntentDescription("A B buttons")
}
