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

    private(set) var events: [TapEvent]

    /// The value that was showing right before the last "zero" toggle,
    /// so a second triple-tap can restore it.
    private(set) var savedValue: Int

    /// True while the button is showing a zeroed-out value.
    private(set) var isZeroed: Bool

    /// When true, this button's count starts over at 0 for each new
    /// calendar day (device-local calendar/time zone) instead of
    /// accumulating indefinitely. `count`/`savedValue` still hold the real
    /// running numbers for whatever day they were last touched on --
    /// `displayCount` is what actually accounts for the rollover.
    private(set) var resetsDaily: Bool = false

    /// When the count was last changed (increment/decrement/zero-toggle).
    /// Used to detect, for a `resetsDaily` button, whether today has had
    /// its first tap yet. Nil for a button that's never been tapped.
    private(set) var lastEventDate: Date?

    
    init(id: UUID = UUID(), name: String, count: Int = 0, resetsDaily: Bool = false) {
        self.id = id
        self.name = name
        self.count = count
        self.savedValue = 0
        self.isZeroed = false
        self.resetsDaily = resetsDaily
        self.lastEventDate = nil
        self.events = []
    }

    // Return false if none were cleaned
    mutating func cleanedUp(_ retentionDays: Int = 1) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let lastMidnight = calendar.startOfDay(for: now)
        guard !events.isEmpty, let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: lastMidnight) else { return false }
        let before = events.count
        print("CounterButtonItem clean \(name) with \(before) tap events before")
        var buttonEvents = events
        buttonEvents.removeAll { $0.timestamp < cutoff }
        print("CounterButtonItem clean \(name) with \(buttonEvents.count) tap events now")
        var gotClean = false
        if buttonEvents.count != before {
            events = buttonEvents
            gotClean = true
        }
        if resetsDaily, let lastDate = lastEventDate, lastDate < lastMidnight {      // If last tap was before midnight, this is the first tap of day
            append(0)
            gotClean = true
            print("CounterButtonItem clean \(name) with reset count to \(events.count) tap events now")
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

