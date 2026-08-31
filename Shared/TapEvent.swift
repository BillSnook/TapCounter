//
//  TapEvent.swift
//  TapCounter (Shared)
//
//  A single recorded change to a button's count (increment, decrement, or
//  zero/restore), captured for later charting. Deliberately minimal for
//  now: the count *after* the change, when it happened, stored on the button.
//

import Foundation

struct TapEvent: Identifiable, Codable, Hashable {
    let id: UUID

    let count: Int          // The button's count after it was updated.
    let timestamp: Date     // The time at which the button was updated.

    init(id: UUID = UUID(), count: Int, timestamp: Date = Date()) {
        self.id = id
        self.count = count
        self.timestamp = timestamp
    }
}
