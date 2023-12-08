//
//  iOSWidgetExtensionBundle.swift
//  iOSWidgetExtension
//
//  Created by Cameron Little on 2023-12-08.
//

import WidgetKit
import SwiftUI

@main
struct iOSWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        iOSWidgetExtension()
        iOSWidgetExtensionLiveActivity()
    }
}
