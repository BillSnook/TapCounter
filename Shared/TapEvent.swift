//
//  TapEvent.swift
//  TapCounter (Shared)
//
//  A single recorded change to a button's count (increment, decrement, or
//  zero/restore), captured for later charting. Deliberately minimal for
//  now: the count *after* the change, when it happened, and which button
//  it belongs to.
//

import Foundation

struct TapEvent: Identifiable, Codable, Hashable {
    let id: UUID

    /// The button's count immediately after this event.
    let count: Int
    let timestamp: Date

    init(id: UUID = UUID(), count: Int, timestamp: Date = Date()) {
        self.id = id
        self.count = count
        self.timestamp = timestamp
    }
}
