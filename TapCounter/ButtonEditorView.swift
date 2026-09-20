//
//  ButtonEditorView.swift
//  TapCounter
//
//  The button creator/editor: names a new functional button or edits an
//  existing one, including its current count.
//

import SwiftUI

struct ButtonEditorView: View {
    @Environment(CounterStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// nil when creating a new button; set when editing an existing one.
    let item: CounterButtonItem?

    @State private var name: String = ""
    @State private var displayCount: Int = 0
    @State private var resetsDaily: Bool = false
    @State private var allowsCountingDown: Bool = false      // If true, counting down is supported
    @State private var allowsNegativeCounts: Bool = false // If true, counts can go below 0
    @State private var allowsZeroingToggle: Bool = false  // If true, count resets to 0 or saved previous value
    @FocusState private var nameFieldFocused: Bool

    private var isEditing: Bool { item != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Pushups, Laps, Score", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($nameFieldFocused)
                }

                Section("Starting Count") {
                    Stepper(value: $displayCount, in: 0...1_000) {
                        Text("\(displayCount)")
                            .font(.title2.monospacedDigit())
                            .contentTransition(.numericText(value: Double(displayCount)))
                            .animation(.snappy, value: displayCount)
                    }
                }

                Section {
                    Toggle("Reset Daily", isOn: $resetsDaily)
                } footer: {
                    Text("Count is 0 until the first tap of each day.")
                }
                Section {
                    Toggle("Allows Counting Down", isOn: $allowsCountingDown)
                } footer: {
                    Text("Count may be decremented.")
                }
                Section {
                    Toggle("Allows Negative Counts", isOn: $allowsNegativeCounts)
                } footer: {
                    Text("Count may go below zero.")
                }
                Section {
                    Toggle("Allows Toggle to zero", isOn: $allowsZeroingToggle)
                } footer: {
                    Text("Count may be toggled between zero and last value.")
                }
            }
            .navigationTitle(isEditing ? "Editing Button" : "Adding Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                print("ButtonEditorView .onAppear, \(item?.name ?? "new button")")
                if let item {
                    name = item.name
                    displayCount = item.displayCount
                    resetsDaily = item.resetsDaily
                    allowsCountingDown = item.allowsCountingDown
                    allowsNegativeCounts = item.allowsNegativeCounts
                    allowsZeroingToggle = item.allowsZeroingToggle
                } else {
                    nameFieldFocused = true
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }  // TODO: Mark name field as required

        if var existing = item {
            existing.update(name: trimmedName, tapCount: existing.tapCount, displayCount: displayCount, resetsDaily: resetsDaily)
            store.replaceButton(existing)
        } else {
            store.addButton(name: trimmedName, displayCount: displayCount, resetsDaily: resetsDaily)
        }
        store.saveAndSync()
        dismiss()
    }
}

#Preview {
    ButtonEditorView(item: nil)
        .environment(CounterStore())
}

