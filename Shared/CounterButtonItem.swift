//
//  CounterButtonItem.swift
//  TapCounter (Shared)
//
//  A single user-created counter button: a name plus a count, with
//  support for the "double tap to zero / restore" alternating behavior.
//

import Foundation

struct CounterButtonItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var count: Int

    private(set) var events: [TapEvent]

    /// The value that was showing right before the last "zero" toggle,
    /// so a second double-tap can restore it.
    var savedValue: Int

    /// True while the button is showing a zeroed-out value.
    var isZeroed: Bool

    /// When true, this button's count starts over at 0 for each new
    /// calendar day (device-local calendar/time zone) instead of
    /// accumulating indefinitely. `count`/`savedValue` still hold the real
    /// running numbers for whatever day they were last touched on --
    /// `displayCount` is what actually accounts for the rollover.
    var resetsDaily: Bool = false

    /// When the count was last changed (increment/decrement/zero-toggle).
    /// Used to detect, for a `resetsDaily` button, whether today has had
    /// its first tap yet. Nil for a button that's never been tapped.
    var lastEventDate: Date?

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

    /// Single tap: increments the count.
    mutating func increment() {
        if 0 == count {
            isZeroed = false
        }
        count += 1
        events.append(TapEvent(count: count))
    }

    /// Double tap: decrements the count.
    mutating func decrement() {
        if count > 0 {
            count -= 1
            events.append(TapEvent(count: count))
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
        events.append(TapEvent(count: count))
    }
}

