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

    private func delete(_ item: CounterButtonItem) {
        if let index = store.buttons.firstIndex(where: { $0.id == item.id }) {
            store.deleteButtons(at: IndexSet(integer: index))
        }
    }
}

#Preview {
    ContentView()
        .environment(CounterStore())
}

