//
//  TapEvent.swift
//  TapCounter (Shared)
//
//  A single recorded change to a button's count (increment, decrement, or
//  zero/restore), captured for later charting. Deliberately minimal for
//  now: the count *after* the change, when it happened, stored on the button.
//

import Foundation

struct TapEvent: Codable, Hashable {
    let tapCount: Int       // The button's count when it was updated (0, -1, 1)
    let displayCount: Int   // The button's value after it was updated.
    let timestamp: Date     // The time at which the button was updated.

    init(tapCount: Int, displayCount: Int, timestamp: Date = Date()) {
        self.tapCount = tapCount
        self.displayCount = displayCount
        self.timestamp = timestamp
    }
}
