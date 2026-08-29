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
        load()
    }

    // MARK: - Mutations

    @discardableResult
    func addButton(name: String, count: Int = 0, resetsDaily: Bool = false) -> CounterButtonItem {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = CounterButtonItem(name: trimmed.isEmpty ? "Untitled" : trimmed, count: count, resetsDaily: resetsDaily)
        buttons.append(item)
        persistAndSync()
        return item
    }

    func updateButton(_ item: CounterButtonItem) {
        guard let index = buttons.firstIndex(where: { $0.id == item.id }) else { return }
        buttons[index] = item
        persistAndSync()
    }

    func deleteButtons(at offsets: IndexSet) {
        buttons.remove(atOffsets: offsets)
        persistAndSync()
    }

    func moveButtons(from source: IndexSet, to destination: Int) {
        buttons.move(fromOffsets: source, toOffset: destination)
        persistAndSync()
    }

    func increment(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].increment()
        persistAndSync()
    }

    func decrement(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].decrement()
        persistAndSync()
    }

    func toggleZero(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].toggleZero()
        persistAndSync()
    }

    // MARK: - Remote sync

    /// Called by the platform connectivity manager when the paired device
    /// sends a newer snapshot. Applies it as-is (last-write-wins) without
    /// re-broadcasting, since it just came from the other device.
    func applyRemoteUpdate(_ remoteButtons: [CounterButtonItem]) {
        guard remoteButtons != buttons else { return }
        isApplyingRemoteUpdate = true
        buttons = remoteButtons
        save()
        isApplyingRemoteUpdate = false
    }

    // MARK: - Persistence

    private func persistAndSync() {
        save()
        guard !isApplyingRemoteUpdate else { return }
        onLocalChange?(buttons)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) {
            buttons = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(buttons) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

