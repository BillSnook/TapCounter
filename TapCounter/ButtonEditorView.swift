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
    @State private var resetsDaily: Bool = false
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
                    Stepper(value: $count, in: 0...1_000) {
                        Text("\(count)")
                            .font(.title2.monospacedDigit())
                            .contentTransition(.numericText(value: Double(count)))
                            .animation(.snappy, value: count)
                    }
                }

                Section {
                    Toggle("Reset Daily", isOn: $resetsDaily)
                } footer: {
                    Text("Count is 0 until the first tap of each day.")
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
                print("ButtonEditorView .onAppear, \(item?.name ?? "Unnamed")")
                if let item {
                    name = item.name
                    count = item.count
                    resetsDaily = item.resetsDaily
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
            existing.update(name: trimmedName, count: count, resetsDaily: resetsDaily)
            store.updateButton(existing)
        } else {
            store.addButton(name: trimmedName, count: count, resetsDaily: resetsDaily)
        }
        dismiss()
    }
}

#Preview {
    ButtonEditorView(item: nil)
        .environment(CounterStore())
}

