//
//  ContentView.swift
//  TapCounter
//
//  The list of created functional buttons, plus entry points for the
//  button creator/editor.
//


/*

I want to collect and chart tap events on phone and watch. I need a list with at least the new count and timestamp for each tap event, linked to their count button. Make it an object so we can add date checks as we will want to delete entries older than 7 (for now) days, and to group the data for display by day or time. When an event is added, delete any events older than those days from that list.

Sometimes we want to count events by day and so start over at 0 for each event of a new day. Add a flag to the CounterButtonItem to save this selection, and describe and allow setting this feature for each button when in edit mode. Add code to implement this so button display shows 0 before any tap event for a day.

Chart pages will be accessible with a right swipe on the watch and in a new tab on the phone. For now just display a message that work is in progress.

 */


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

