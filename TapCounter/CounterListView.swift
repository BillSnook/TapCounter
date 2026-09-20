//
//  CounterListView.swift
//  TapCounter
//
//  The list of created functional buttons, plus entry points for the
//  button creator/editor. Lives in its own "Counters" tab; see ContentView.
//

import SwiftUI

struct CounterListView: View {
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
                            if editingItem == nil {
                                store.moveButtons(from: source, to: destination)
                            }
                        }
                        .frame(maxWidth: 340)
                    } footer: {
                        Text("Tap to count up. Triple tap to count down. Long press to zero out/restore. Swipe right to edit. Swipe left to delete.")
                    }
                }
            }
            .navigationTitle("Tap Counter")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if store.buttons.count > 1 {    // Only change order of (move) buttons if more than 1
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewButtonEditor = true
                    } label: {
                        Label("Add Button", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewButtonEditor) {
                ButtonEditorView(item: nil)
            }
            .sheet(item: $editingItem) { item in
                ButtonEditorView(item: item)
            }
            .onAppear {     // This closure should complete before any rendered frames appear
                print("CounterListView .onAppear, \(store.buttons.count) buttons")
                store.cleanEvents()
//                for button in store.buttons {
//                    print("CounterListView .onAppear, after store.cleanEvents, \(button.name) has \(button.events.count) events, count of \(button.count)")
//                }
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
    CounterListView()
        .environment(CounterStore())
}
