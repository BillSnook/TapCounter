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

    /// The value that was showing right before the last "zero" toggle,
    /// so a second double-tap can restore it.
    var savedValue: Int

    /// True while the button is showing a zeroed-out value.
    var isZeroed: Bool

    var createdAt: Date

    init(id: UUID = UUID(), name: String, count: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
        self.savedValue = 0
        self.isZeroed = false
        self.createdAt = Date()
    }

    /// Single tap: increments the count.
    mutating func increment() {
        if 0 == count {
            isZeroed = false
        }
        count += 1
    }

    /// Double tap: decrements the count.
    mutating func decrement() {
        if count > 0 {
            count -= 1
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
    }
}

