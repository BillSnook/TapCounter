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

    @State private var isPresentingNewButtonEditor = false
    @State private var editingItem: CounterButtonItem?

    var body: some View {
        NavigationStack {
            List {
                if store.buttons.isEmpty {
                    ContentUnavailableView(
                        "No Buttons Yet",
                        systemImage: "hand.tap",
                        description: Text("Tap the + button to create your first counter.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(store.buttons) { item in
                            CounterButtonRow(item: item)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingItem = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onMove { source, destination in
                            store.moveButtons(from: source, to: destination)
                        }
                    } footer: {
                        Text("Tap to count up. Double tap to count down. Triple tap to zero out/restore. Swipe right to edit. Swipe left to delete.")
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Tap Counter")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewButtonEditor = true
                    } label: {
                        Label("Add Button", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !store.buttons.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewButtonEditor) {
                ButtonEditorView(item: nil)
            }
            .sheet(item: $editingItem) { item in
                ButtonEditorView(item: item)
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

