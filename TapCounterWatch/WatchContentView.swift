//
//  WatchContentView.swift
//  TapCounterWatch
//
//  Displays the same functional buttons created on the iPhone.
//

import SwiftUI

private enum Page: Hashable {
    case charts
    case counters
}

struct WatchContentView: View {
    @State private var selection: Page = .counters

    var body: some View {
        TabView(selection: $selection) {
            WatchChartsView()
                .tag(Page.charts)
            WatchCounterListView()
                .tag(Page.counters)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

#Preview {
    WatchContentView()
        .environment(CounterStore())
}

