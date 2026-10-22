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
    /// change originated from `receivedButtonsUpdate`, to avoid sync loops.
    var onButtonChanges: (([CounterButtonItem]) -> Void)?
    var onStatusChanges: ((RemoteStatusMessage) -> Void)?

    private let fileURL: URL            // Save file address
//    private var doNotSync = false

    init(filename: String = "counters.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent(filename)

        loadFromFile()      // Restore buttons list from last-saved file, if any
        print("CounterStore init, loaded \(buttons.count) buttons from file, v2.0")
    }

    // MARK: - Button management

    func addButton(_ item: CounterButtonItem)  {
        buttons.append(item)
    }

    func updateButton(_ item: CounterButtonItem) {
        guard let index = buttons.firstIndex(where: { $0.id == item.id }) else { return }
        buttons[index] = item
    }

    func deleteButtons(at offsets: IndexSet) {
        buttons.remove(atOffsets: offsets)
        print("CounterStore deleteButtons, saveAndSync")
        saveAndSync()
    }

    func moveButtons(from source: IndexSet, to destination: Int) {
        buttons.move(fromOffsets: source, toOffset: destination)
        print("CounterStore moveButtons, saveAndSync")
        saveAndSync()
    }

    
// MARK: - Tap management

    func increment(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].increment()
        print("\nCounterStore increment, saveAndSync")
        saveAndSync()
    }

    func decrement(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].decrement()
        print("\nCounterStore decrement, saveAndSync")
        saveAndSync()
    }

    func toggleZero(id: UUID) {
        guard let index = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[index].toggleZero()
        print("\nCounterStore toggleZero, saveAndSync")
        saveAndSync()
    }

    // MARK: - Debug display methods
/* */   /// Display select button data
    func showTapEvents(_ events: [TapEvent], _ title: String = "") {
        if !title.isEmpty { print("    showTapEvents, \(title)") }
        for event in events {
            print("      showTapEvents: \(event.tapCount) - \(event.displayCount) at \(formatDate(event.timestamp))")
        }
    }

    func showButtonEvents(_ button: CounterButtonItem, _ showEventListToo: Bool = true) {
        print("    showButtonEvents, button '\(button.name)' has \(button.tapCount) - \(button.displayCount) (tapCount - displayCount)")
        guard showEventListToo else { return }
        for event in button.events {
            print("      showButtonEvents: \(event.tapCount) - \(event.displayCount) at \(formatDate(event.timestamp))")
        }
    }

    func showButtons(_ desc: String = "", showEventListToo: Bool = true) {
        print("  showButtons, \(desc.isEmpty ? "" : "\(desc), ")\(buttons.count) buttons")
        for button in buttons {
            showButtonEvents(button, showEventListToo)
        }
    }

/* */

    func matchButton(_ button: CounterButtonItem) -> Int? {
        return buttons.firstIndex(where: { $0.id == button.id })
    }


    // MARK: - Remote sync

    func receivedStatusUpdate(_ remoteStatus: RemoteStatusMessage) {
        print("\nCounterStore receivedStatusUpdate - status code: \(remoteStatus.statusCode), message: \(remoteStatus.statusMessage)")
#if os(iOS)
#else
#endif
    }

    /// Called by the platform connectivity manager when the paired device
    /// sends a newer snapshot. We need to collate this record with the local copy
    /// since one or both devices may have new entries since last connected.
    /// Do not re-broadcast, unless local changes were made, since it just came from the other device.
    func receivedButtonsUpdate(_ remoteButtons: [CounterButtonItem]) {
        print("\n \(formatDate()) * CounterStore receivedButtonsUpdate - remoteButtons count: \(remoteButtons.count)")

        guard remoteButtons != buttons else { return }  // Skip if no changes
//#if os(iOS)         // Only align button event logs if on iPhone side, to avoid race conditions
//        collateEvents(remoteButtons)

//#else
        buttons = remoteButtons
//#endif
        checkEvents()       // Ensure we save new, checked events
   }

    func collateEvents(_ remoteButtons: [CounterButtonItem]) {
//        guard !remoteButtons.isEmpty else {
//            // This could be a signal that the watch has just started and needs data from us
//            print(" CounterStore collateEvents remote has no buttons which may signal it has just started up - or is an error")
//            return
//        }
        var updateWatch = false
        for watchButton in remoteButtons {
            print("  CounterStore collateEvents remote '\(watchButton.name)' : \(watchButton.displayCount) has \(watchButton.events.count) events")
            showButtonEvents(watchButton)
            if let index = buttons.firstIndex(where: { $0.id == watchButton.id }) {   // Get local index of matching button, if any

                var localButton = buttons[index]
                print("  CounterStore collateEvents local  '\(localButton.name)' : \(localButton.displayCount) has \(localButton.events.count) events")
                showButtonEvents(localButton)

                let watchSet = Set(watchButton.events)
                let localSet = Set(localButton.events)
                let watchOnlySet = watchSet.subtracting(localSet)           // Events in watch but not local
                let localOnlySet = localSet.subtracting(watchSet)           // Events in local but not watch
// Determine which scenario is in play
                if localOnlySet.isEmpty {       // Normal case - update from watch, local unchanged
                    buttons[index] = watchButton
                    print("  CounterStore collateEventss, no local changes for '\(localButton.name)', displayCount \(watchButton.displayCount)")
                } else {
                    // Merge local events with new watch events
                    if watchOnlySet.isEmpty {
                        print(" -> ERROR: CounterStore collateEvents, watchSet empty for '\(watchButton.name)'")
                    }  else {
                        let commonEventSet = watchSet.intersection(localSet)        // Events in both
//                        var displayCount = localButton.displayCount
                        print("  Common events, local displayCount \(localButton.displayCount), watch displayCount \(watchButton.displayCount)")
                        let commonEventsArray = Array(commonEventSet).sorted { $0.timestamp < $1.timestamp }
                        showTapEvents(commonEventsArray)
                        print("  Watch-only Events")
                        let watchEventsArray = Array(watchOnlySet).sorted { $0.timestamp < $1.timestamp }
                        showTapEvents(watchEventsArray)
                        print("  Phone-only Events")
                        let phoneEventsArray = Array(localOnlySet).sorted { $0.timestamp < $1.timestamp }
                        showTapEvents(phoneEventsArray)
                        print("  Local displayCount \(localButton.displayCount), watch displayCount \(watchButton.displayCount)")
                        // This is ok but displayCount and lastDate are wrong - needs grooming so counts are accurate
                        let newEventsSet = watchSet.symmetricDifference(localSet)  // Events in either but not both
                        let sortedNewEventsArray = Array(newEventsSet).sorted { $0.timestamp < $1.timestamp }

                        let max = commonEventsArray.count
                        if 0 == max {
                            print("CounterStore collateEvents with no common events for button '\(localButton.name)'")
                            if let last = sortedNewEventsArray.last {
                                localButton.replaceEvents(sortedNewEventsArray, last.displayCount, last.timestamp)
                            }
                        } else {
                            var updatedEventArray: [TapEvent] = []
                            var runningDisplayCount = 0
                            var commonIndex = 0
                            var nextEntry: TapEvent?
                            var priorEntry: TapEvent?
                            for event in sortedNewEventsArray {
                                // for this new event, collect all the events before it in the common events,
                                while commonIndex < max {
                                    priorEntry = nextEntry
                                    nextEntry = commonEventsArray[commonIndex]
                                    if event.timestamp > nextEntry!.timestamp {
                                        runningDisplayCount = nextEntry!.displayCount
                                        updatedEventArray.append(nextEntry!)
                                        commonIndex += 1
                                    }
                                }
                                // then apply this one, adjusting the display counts as we go
                                if let lastEntry = priorEntry {
                                    switch lastEntry.tapCount {
                                    case 0 where lastEntry.displayCount == 0:     // This should be a daily reset entry
                                        // We include it and update the accumulating displaycount
                                        print("Tap event reset daily entry")
                                        updatedEventArray.append(lastEntry)
                                        runningDisplayCount = 0
                                    case 0:
                                        print("Tap event unsaved value \(lastEntry.tapCount), display \(lastEntry.displayCount),  toggle?")
                                    case 1:
                                        print("Tap event increment")
                                        updatedEventArray.append(lastEntry)
                                        runningDisplayCount += 1
                                    case -1:
                                        print("Tap event decrement")
                                        updatedEventArray.append(lastEntry)
                                        runningDisplayCount -= 1
                                    default:
                                        print("Tap event saved value \(lastEntry.tapCount), display \(lastEntry.displayCount), untoggle")
                                        runningDisplayCount += lastEntry.tapCount
                                    }
                                }
                                priorEntry = event
                            }
                            showTapEvents(updatedEventArray, "Final updated Array")
                            localButton.replaceEvents(updatedEventArray, runningDisplayCount,updatedEventArray.last?.timestamp ?? Date())
                            buttons[index] = localButton
                            updateWatch = true
                        }
                    }
                    print("CounterStore collateEvents for '\(localButton.name)' after merge")
                    showButtonEvents(localButton)
                }
            } else {
                print(" -> ERROR: CounterStore collateEvents, local button for '\(watchButton.name)' is not found - deleted locally?")
            }
        }
        if updateWatch {
            print("CounterStore collateEvents, saveAndSync because watch needs updating")
            saveAndSync()   // We updated a button and need to tell the watch
        } else {
            print("CounterStore collateEvents, saveToFile")
            saveToFile()
        }
    }

    // MARK: - Cleanup tap event lists

    @discardableResult func checkDailyResets(syncIfSet: Bool = true) -> Bool {     // If reset-total daily flag is set for any button, append special tap event
        print(" CounterStore checkDailyResets, \(buttons.count) buttons")
        var didReset = false
        for var button in buttons {
            if button.dailyReset() {
                didReset = true
                updateButton(button)
            }
        }
        if syncIfSet && didReset {  // If allowed and any button's reset occurred, update remote
            print(" CounterStore checkDailyResets did update some buttons, saveAndSync")
            saveAndSync()
        }
        return didReset
    }

    @discardableResult func clearExpiredEvents(syncIfSet: Bool = false) -> Bool {
        print(" CounterStore clearExpiredEvents, \(buttons.count) buttons")
        var cleaned = false
        for var button in buttons {
            if button.expiredEvents() {
                cleaned = true
                updateButton(button)
            }
        }
        if syncIfSet && cleaned {   // If allowed and any button updated, save all to file and sync with other device
            print(" CounterStore clearExpiredEvents did clean, saveAndSync")
            saveAndSync()
        }
        return cleaned
    }

    func checkEvents() {    // Called on activate, when new events come in from the remote device
        print("CounterStore checkEvents, \(buttons.count) buttons")
        let someReset = checkDailyResets(syncIfSet: false)
        let someCleared = clearExpiredEvents(syncIfSet: false)
        if someReset || someCleared {
            print("CounterStore checkEvents, event list change occurred, save and sync events")
            showButtons()
            saveAndSync()
        } else {
            print("CounterStore checkEvents, no event list change occurred")
            showButtons()
            saveToFile()
        }
    }


    // MARK: - Persistence

    func saveAndSync() {        // Save and send changes to other device
        print("CounterStore saveAndSync, saveToFile")
        saveToFile()
//        guard ! else { return }
        showButtons("saveAndSync")
        onButtonChanges?(buttons)
    }

    private func loadFromFile() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) {
            buttons = decoded
            print("CounterStore loadFromFile, read \(buttons.count) buttons")
        }
        return
    }

    private func saveToFile() {
        guard let data = try? JSONEncoder().encode(buttons) else { return }
        try? data.write(to: fileURL, options: .atomic)
        print("CounterStore saveToFile, data size: \(data)")
    }
}

