//
//  AppIntent.swift
//  iOSWidgetExtension
//
//  Created by Cameron Little on 2023-12-08.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dolphin Ctrl"
    static var description = IntentDescription("A B buttons")
}
