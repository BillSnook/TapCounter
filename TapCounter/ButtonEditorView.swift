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
    @State private var count: Int = 0
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
                    Stepper(value: $count, in: -1_000_000...1_000_000) {
                        Text("\(count)")
                            .font(.title2.monospacedDigit())
                            .contentTransition(.numericText(value: Double(count)))
                            .animation(.snappy, value: count)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Button" : "New Button")
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
                if let item {
                    name = item.name
                    count = item.count
                } else {
                    nameFieldFocused = true
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if var existing = item {
            existing.name = trimmed
            existing.count = count
            store.updateButton(existing)
        } else {
            store.addButton(name: trimmed, count: count)
        }
        dismiss()
    }
}

#Preview {
    ButtonEditorView(item: nil)
        .environment(CounterStore())
}

