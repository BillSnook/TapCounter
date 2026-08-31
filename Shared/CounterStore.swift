//
//  CounterStore.swift
//  TapCounter (Shared)
//
//  Observable, on-disk store of counter buttons. Used identically by the
//  iOS app and the watchOS app; each device keeps its own local copy and
//  the platform-specific connectivity manager (PhoneConnectivityManager /
//  WatchConnectivityManager) keeps the two in sync via WatchConnectivity.
//

import Foundation
import Observation

@Observable
final class CounterStore {
    private(set) var buttons: [CounterButtonItem] = []

    /// Set by the platform layer (PhoneConnectivityManager / WatchConnectivityManager)
    /// to push local changes out to the paired device. Not called when a
    /// change originated from `applyRemoteUpdate`, to avoid sync loops.
    var onLocalChange: (([CounterButtonItem]) -> Void)?

    private let fileURL: URL
    private var isApplyingRemoteUpdate = false

    init(filename: String = "counters.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent(filename)
        load()          // Restore buttons list from last-saved file, if any saved
        print("CounterStore loaded, \(buttons.count) buttons")
    }

    // MARK: - Mutations

    func addButton(name: String, count: Int = 0, resetsDaily: Bool = false)  {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = CounterButtonItem(name: trimmed.isEmpty ? "Untitled" : trimmed, count: count, resetsDaily: resetsDaily)
        buttons.append(item)
        saveAndSync()
        return
    }

    func updateButton(_ item: CounterButtonItem) {
        guard let index = buttons.firstIndex(where: { $0.id == item.id }) else { return }
        buttons[index] = item
        saveAndSync()
    }

    func deleteButtons(at offsets: IndexSet) {
        buttons.remove(atOffsets: offsets)
        saveAndSync()
    }

    func moveButtons(from source: IndexSet, to destination: Int) {
        buttons.move(fromOffsets: source, toOffset: destination)
        saveAndSync()
    }

    func increment(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].increment()
        saveAndSync()
    }

    func decrement(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].decrement()
        saveAndSync()
    }

    func toggleZero(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].toggleZero()
        saveAndSync()
    }

    func cleanEvents() {
        print("CounterStore cleanEvents, \(buttons.count) buttons")
//        showButtons("start")
        var cleaned = false
        for var button in buttons {
            if button.cleanedUp() {
                print("CounterStore cleanEvents has cleaned '\(button.name)' : \(button.count) has \(button.events.count) events")
                cleaned = true
                updateButton(button)
            }
        }
        if cleaned {        // If any button cleaned
            saveAndSync()
        }
//        showButtons("end")
    }

    func showEvents(_ button: CounterButtonItem) {
        print("    showEvents, '\(button.name)' has \(button.events.count) events and display count is \(button.count)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "en_US")
        for event in button.events {
            print("      showEvents: \(event.count) at \(dateFormatter.string(from: event.timestamp))")
        }
    }
    
    func showButtons(_ desc: String) {
        print("  showButtons, \(desc), \(buttons.count) buttons")
        for button in buttons {
            showEvents(button)
        }
    }

    // MARK: - Remote sync

    /// Called by the platform connectivity manager when the paired device
    /// sends a newer snapshot. Applies it as-is (last-write-wins) without
    /// re-broadcasting, since it just came from the other device.
    func applyRemoteUpdate(_ remoteButtons: [CounterButtonItem]) {
        print("CounterStore applyRemoteUpdate")
        guard remoteButtons != buttons else { return }
        isApplyingRemoteUpdate = true
        buttons = remoteButtons
        save()
        isApplyingRemoteUpdate = false
    }

    // MARK: - Persistence

    private func saveAndSync() {
//
        print("CounterStore saveAndSync, \(buttons.count) buttons")
        for button in buttons {
            print("CounterStore saveAndSync '\(button.name)' : \(button.count) has \(button.events.count) events")
        }
//
        save()
        guard !isApplyingRemoteUpdate else { return }
        onLocalChange?(buttons)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) {
            buttons = decoded
        }
        print("CounterStore load (from file), read \(buttons.count) buttons")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(buttons) else { fatalError(); return }
        try? data.write(to: fileURL, options: .atomic)
        print("CounterStore save (to file), data size: \(data)")
    }
}

