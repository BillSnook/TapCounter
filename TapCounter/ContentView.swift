//
//  ContentView.swift
//  TapCounter
//
//  The list of created functional buttons, plus entry points for the
//  button creator/editor.
//

import SwiftUI

struct ContentView: View {
    @Environment(CounterStore.self) private var store

    var body: some View {
        TabView {
            CounterListView()
                .tabItem {
                    Label("Counters", systemImage: "list.bullet")
                }
            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.bar.xaxis")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(CounterStore())
}

