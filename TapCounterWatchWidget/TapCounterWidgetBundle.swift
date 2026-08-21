//
//  TapCounterWidgetBundle.swift
//  TapCounterWatchWidget
//
//  Entry point for the watch complication extension.
//

import WidgetKit
import SwiftUI

@main
struct TapCounterWidgetBundle: WidgetBundle {
    var body: some Widget {
        TapCounterComplication()
    }
}
