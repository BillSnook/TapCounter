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
    /// change originated from `applyUpdatedButtons`, to avoid sync loops.
    var onLocalChange: (([CounterButtonItem]) -> Void)?
    let dateFormatter = DateFormatter()

    private let fileURL: URL
    private var isApplyingRemoteUpdate = false

    init(filename: String = "counters.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent(filename)
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "en_US")
        loadFromFile()      // Restore buttons list from last-saved file, if any
        print("CounterStore init, loaded \(buttons.count) buttons from file")
    }

    // MARK: - Mutations

    func addButton(name: String, displayCount: Int = 0, resetsDaily: Bool = false)  {  // TODO: check for duplicate names
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = CounterButtonItem(name: trimmed.isEmpty ? "Untitled" : trimmed, displayCount: displayCount, resetsDaily: resetsDaily)
        buttons.append(item)
    }

    func replaceButton(_ item: CounterButtonItem) {
        guard let index = buttons.firstIndex(where: { $0.id == item.id }) else { return }
        buttons[index] = item
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
//        print("CounterStore cleanEvents, \(buttons.count) buttons")
        var cleaned = false
        for var button in buttons {
            if button.cleanedUp() {
                cleaned = true
                replaceButton(button)
            }
        }
        if cleaned {        // If any button cleaned or reset, save to file and sync with other device
            saveAndSync()
        }
    }

/* */
    func showTapEvents(_ events: [TapEvent]) {
//        print("    showTapEvents, \(events.count) events")
        for event in events {
            print("      showTapEvents: \(event.tapCount) at \(dateFormatter.string(from: event.timestamp))")
        }
    }

    func showEvents(_ button: CounterButtonItem, _ showEventList: Bool = true) {
        print("    showEvents, '\(button.name)' has \(button.events.count) events and display count is \(button.displayCount)")
        guard showEventList else { return }
        for event in button.events {
            print("      showEvents: \(event.tapCount) at \(dateFormatter.string(from: event.timestamp))")
        }
    }

    func showButtons(_ desc: String, _ showEventList: Bool = true) {
        print("  showButtons, \(desc), \(buttons.count) buttons")
        for button in buttons {
            showEvents(button, showEventList)
        }
    }
/* */

    func matchButton(_ button: CounterButtonItem) -> Int? {
        guard let index = buttons.firstIndex(where: { $0.id == button.id }) else { return nil }
        return index
    }


    // MARK: - Remote sync

    /// Called by the platform connectivity manager when the paired device
    /// sends a newer snapshot. We need to collate this record with the local copy
    /// since one or both devices may have new entries since last connected.
    /// Do not re-broadcast, unless local changes were made, since it just came from the other device.
    func applyUpdatedButtons(_ remoteButtons: [CounterButtonItem]) {
        print("\nCounterStore applyUpdatedButtons - got data from remote device, remoteButtons \(remoteButtons.isEmpty ? "is" : "is not") empty")
        guard remoteButtons != buttons else { return }  // Skip if no changes
        isApplyingRemoteUpdate = true

#if os(iOS)         // Only align button event logs if on iPhone side, to avoid race conditions
        collateEvents(remoteButtons)
#else
        buttons = remoteButtons
        saveToFile()
        isApplyingRemoteUpdate = false
#endif
   }

    func collateEvents(_ remoteButtons: [CounterButtonItem]) {
        if remoteButtons.isEmpty {
            // This should be a signal that the watch has just started and needs data from us
            print("CounterStore collateEvents remote has no buttons which may signal it has just started up")
        }
        var updateWatch = false
        for watchButton in remoteButtons {
            print("CounterStore collateEvents remote '\(watchButton.name)' : \(watchButton.displayCount) has \(watchButton.events.count) events")
            showEvents(watchButton)
            if let index = matchButton(watchButton) {   // Get local index of matching button, if any
                var localButton = buttons[index]
                print("CounterStore collateEvents local  '\(localButton.name)' : \(localButton.displayCount) has \(localButton.events.count) events")
                showEvents(localButton)

                let watchSet = Set(watchButton.events)
                let localSet = Set(localButton.events)
//                let newEventSet = watchSet.symmetricDifference(localSet)  // Events in one but not both
                let watchOnlySet = watchSet.subtracting(localSet)           // Events in watch but not local
                let localOnlySet = localSet.subtracting(watchSet)           // Events in local but not watch
                let commonEventSet = watchSet.intersection(localSet)        // Events in both

                if localOnlySet.isEmpty {       // Normal case - update from watch, local unchanged
                    buttons[index] = watchButton
                    print("  Collate Events, no local changes for '\(localButton.name)', displayCount \(watchButton.displayCount)")
                    continue
                } else {
                    // Merge local events with new watch events
                    if watchOnlySet.isEmpty {
                        print(" -> ERROR: CounterStore collateEvents, watchSet empty for '\(watchButton.name)'")
                        continue
                    }  else {
//                        var displayCount = localButton.displayCount
//                        let sortedNewEventsArray = Array(newEventSet).sorted { $0.timestamp < $1.timestamp }
                        print("  Common events, local displayCount \(localButton.displayCount), watch displayCount \(watchButton.displayCount)")
                        let commonEventsArray = Array(commonEventSet).sorted { $0.timestamp < $1.timestamp }
                        showTapEvents(commonEventsArray)
                        print("  Watch Event differences")
                        let watchEventsArray = Array(watchOnlySet).sorted { $0.timestamp < $1.timestamp }
                        showTapEvents(watchEventsArray)
                        print("  Phone Event differences")
                        let phoneEventsArray = Array(localOnlySet).sorted { $0.timestamp < $1.timestamp }
                        showTapEvents(phoneEventsArray)
                        // This is good but counts and lastDate are wrong
                        // Needs better grooming so counts are accurate
//                        var displayCount = commonEventsArray
                        print("  Collate Events, local displayCount \(localButton.displayCount), watch displayCount \(watchButton.displayCount)")
//                        for event in sortedNewEventsArray {
//                            displayCount += event.count
//                        }

//                        let latestTimeStamp = fullEventList.last?.timestamp ?? Date()
//                        localButton.updateButton(fullEventList, displayCount, latestTimeStamp)
                        //
//                        buttons[index] = localButton
//                        updateWatch = true
                    }
                    print("CounterStore collateEvents for '\(localButton.name)' after merge")
                    showEvents(localButton)
                }
            } else {
                print(" -> ERROR: CounterStore collateEvents, local button for '\(watchButton.name)' is not found - deleted locally?")
            }
        }
        isApplyingRemoteUpdate = false
        if updateWatch {
            saveAndSync()   // We updated a button and need to tell the watch
        } else {
            saveToFile()
        }
    }

    // MARK: - Persistence

    func saveAndSync() {        // Save and send changes to other device
//        print("CounterStore saveAndSync, \(buttons.displayCount) buttons")
//        for button in buttons {
//            print("CounterStore saveAndSync '\(button.name)' : \(button.displayCount) has \(button.events.count) events")
//        }

        saveToFile()
        guard !isApplyingRemoteUpdate else { return }
        showButtons("saveAndSync", false)
        onLocalChange?(buttons)
    }

    private func loadFromFile() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) {
            buttons = decoded
        }
        print("CounterStore loadFromFile, read \(buttons.count) buttons")
    }

    private func saveToFile() {
        guard let data = try? JSONEncoder().encode(buttons) else { return }
        try? data.write(to: fileURL, options: .atomic)
        print("CounterStore saveToFile, data size: \(data)")
    }

    func startingUp(_ flag: Bool) {
        showButtons("startingUp")
        if  buttons.isEmpty {
            onLocalChange?(buttons)
        }
        print("CounterStore startingUp ( disabled: send starting signal to remote)")
    }
}

