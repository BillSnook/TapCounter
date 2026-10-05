//
//  CounterButtonItem.swift
//  TapCounter (Shared)
//
//  A single user-created counter button: a name plus a count and timestamp, with
//  support for the "long press tap to zero / restore" alternating behavior.
//

import Foundation

let dateFormatter = DateFormatter()

func formatDate(_ thisDate: Date = Date())-> String {
//    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.setLocalizedDateFormatFromTemplate("h:mm:SS")
    return dateFormatter.string(from: thisDate)
}

struct RemoteStatusMessage: Codable {
    private(set) var statusCode: Int
    private(set) var statusMessage: String
}

struct CounterButtonItem: Identifiable, Codable, Equatable, Hashable {
    private(set) var id: UUID
    private(set) var name: String
    private(set) var tapCount: Int
    private(set) var displayCount: Int
    private(set) var lastEventDate: Date = Date()   // When the count was last changed (inc/dec/zero-toggle).

    private(set) var savedValue: Int = 0    // The count before the last "zero" toggle,
    private(set) var isZeroed: Bool = false // True while the button is showing a zeroed-out value.

    private(set) var events: [TapEvent] = []

    private(set) var resetsDaily: Bool = false          // If true, count starts over at 0 each day
    private(set) var allowsCountingDown: Bool = true    // If true, counting down is supported
    private(set) var allowsNegativeCounts: Bool = false // If true, counts can go below 0
    private(set) var allowsZeroingToggle: Bool = true   // If true, count resets to 0 or saved previous value


    init(id: UUID = UUID(), name: String, tapCount: Int = 0, displayCount: Int = 0, resetsDaily: Bool = false, allowsCountingDown: Bool = false, allowsNegativeCounts: Bool = false, allowsZeroingToggle: Bool = false) {
        self.id = id
        self.name = name
        self.tapCount = tapCount
        self.displayCount = displayCount
        self.resetsDaily = resetsDaily
        self.allowsCountingDown = allowsCountingDown
        self.allowsNegativeCounts = allowsNegativeCounts
        self.allowsZeroingToggle = allowsZeroingToggle
    }

// MARK: - Cleanup events
    // Return true if any were removed due to age
    mutating func eventsRemoved(_ retentionDays: Int = 7) -> Bool {
        print("CounterButtonItem eventsRemoved")
        guard !events.isEmpty else { return false }
        let cutoff = cutoffDate(retentionDays)
        let before = events.count
        print("CounterButtonItem eventsRemoved \(name) with \(before) tap events before")
        var buttonEvents = events
        buttonEvents.removeAll { $0.timestamp < cutoff }
        print("CounterButtonItem eventsRemoved \(name) with \(before - buttonEvents.count) tap events removed")
        if buttonEvents.count != before {
            events = buttonEvents
            return true
        }
        return false
    }

    // Ensure new day starts at zero count if needed
    mutating func dailyReset() -> Bool {
        let cutoff = cutoffDate(0)  // A date at a past midnight
                                    // If lastEventDate is before this date,
                                    // we signal a daily reset is happening
        print("CounterButtonItem dailyReset, cutoff is \(formatDate(cutoff)), lastEventDate is \(formatDate(lastEventDate))")
        guard resetsDaily,
//              let cutoff = cutoffDate(0),    // If last tap was before midnight
              lastEventDate < cutoff
        else { return false }
        displayCount = 0                    // This if before the first tap of the day
        append(0)           // Signal remote that daily reset has occurred
        print("CounterButtonItem dailyReset '\(name)', reset tap events count now")
        return true
    }

    func cutoffDate(_ daysAgo: Int = 7) -> Date {    // Return days ago midnight as Date
        let calendar = Calendar.current
        if daysAgo == 0 { // Test, to use -2 minutes as reset time to test reset behaviour
            return calendar.date(byAdding: .minute, value: -2, to: Date()) ?? Date()
        }
        return calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date())) ?? Date()
    }

//  MARK: - Button editing
    mutating func update(name: String, tapCount: Int, displayCount: Int, resetsDaily: Bool, allowsCountingDown: Bool, allowsNegativeCounts: Bool, allowsZeroingToggle: Bool) {
        self.name = name
        self.tapCount = tapCount
        self.displayCount = displayCount
        self.resetsDaily = resetsDaily
        self.allowsCountingDown = allowsCountingDown
        self.allowsNegativeCounts = allowsNegativeCounts
        self.allowsZeroingToggle = allowsZeroingToggle
    }

    mutating func append(_ eventCount: Int) {
        tapCount = eventCount
        let event = TapEvent(tapCount: tapCount, displayCount: displayCount)
        self.lastEventDate = event.timestamp
        events.append(event)
    }

    //  MARK: - Tap responses
    /// Single tap: increments the count.
    mutating func increment() {
        if 0 == displayCount {
            isZeroed = false
        }
        displayCount += 1
        append(1)
    }

    /// Triple tap: decrements the count.
    mutating func decrement() {
        if allowsCountingDown && (allowsNegativeCounts || displayCount > 0) {
            displayCount -= 1
            append(-1)
        }
    }

    /// Long press: alternates between zeroing the current value and
    /// restoring the value that was showing before it was zeroed.
    mutating func toggleZero() {
        guard allowsZeroingToggle else { return }
        if isZeroed {
            if savedValue != 0 {
                displayCount = savedValue
                tapCount = 0
                append(savedValue)
            }
            isZeroed = false
        } else {
            if displayCount != 0 {
                savedValue = displayCount
                tapCount = savedValue
                displayCount = 0
                append(-savedValue)
                isZeroed = true
            }
        }
    }
}

