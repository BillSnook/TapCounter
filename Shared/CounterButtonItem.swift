//
//  CounterButtonItem.swift
//  TapCounter (Shared)
//
//  A single user-created counter button: a name plus a count, with
//  support for the "double tap to zero / restore" alternating behavior.
//

import Foundation

struct CounterButtonItem: Identifiable, Codable, Equatable, Hashable {
    private(set) var id: UUID
    private(set) var name: String
    private(set) var count: Int

    private(set) var savedValue: Int = 0    // The value that was the count before the last "zero" toggle,
    private(set) var isZeroed: Bool = false // True while the button is showing a zeroed-out value.
    private(set) var lastEventDate: Date = Date()   // When the count was last changed (increment/decrement/zero-toggle).

    private(set) var events: [TapEvent] = []

    private(set) var resetsDaily: Bool = false          // If true, this button's count starts over at 0 each new day
    private(set) var allowsCountDown: Bool = false      // If true, counting down is supported
    private(set) var allowsNegativeCounts: Bool = false // If true, counts can go below 0
    private(set) var allowsZeroingToggle: Bool = false  // If true, count resets to 0 or saved previous value


    init(id: UUID = UUID(), name: String, count: Int = 0, resetsDaily: Bool = false) {
        self.id = id
        self.name = name
        self.count = count
        self.resetsDaily = resetsDaily
    }

    // Return true if any were cleaned or any were reset
    mutating func cleanedUp(_ retentionDays: Int = 7) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        guard !events.isEmpty, let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: midnight) else { return false }
        let before = events.count
//        print("CounterButtonItem cleanedUp for \(name) with \(before) tap events before")
        var buttonEvents = events

        // Prune entries before retentionDays ago
        buttonEvents.removeAll { $0.timestamp < cutoff }
        var gotClean = false
        if buttonEvents.count != before {
//            print("CounterButtonItem cleanedUp for \(name) with \(buttonEvents.count) tap events")
            events = buttonEvents
            gotClean = true
        }

        // Ensure new day starts at zero count
//        let testDate = calendar.date(byAdding: .minute, value: -2, to: now) ?? now    // Debug test
        if resetsDaily, lastEventDate < midnight {      // If last tap was before midnight, this is the first tap of day
            append(0)
            gotClean = true
///            print("CounterButtonItem cleanedUp \(name) with reset count to \(events.count) tap events now")
        }
        return gotClean
    }

    mutating func updateEvents(_ updatedEvents: [TapEvent]) {
        self.events = updatedEvents
    }

    // After editing
    mutating func update(name: String, count: Int, resetsDaily: Bool) {
        self.name = name
        self.count = count
        self.resetsDaily = resetsDaily
    }

    mutating func append(_ count: Int) {
        self.count = count                // Needed for display/updates
        let event = TapEvent(count: count)
        self.lastEventDate = event.timestamp
        events.append(event)
    }

    /// Single tap: increments the count.
    mutating func increment() {
        if 0 == count {
            isZeroed = false
        }
        count += 1
        append(count)
    }

    /// Double tap: decrements the count.
    mutating func decrement() {
        if count > 0 {
            count -= 1
            append(count)
        }
    }

    /// Triple tap: alternates between zeroing the current value and
    /// restoring the value that was showing before it was zeroed.
    mutating func toggleZero() {
        if isZeroed {
            count = savedValue
            isZeroed = false
        } else {
            savedValue = count
            count = 0
            isZeroed = true
        }
        append(count)
    }
}

