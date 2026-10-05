//
//  CounterButtonItemTests.swift
//  TapCounterTests
//

import XCTest
@testable import TapCounter

final class CounterButtonItemTests: XCTestCase {

    func testIncrement() {
        var item = CounterButtonItem(name: "Pushups", displayCount: 5)
        item.increment()
        XCTAssertEqual(item.displayCount, 6)
    }

    func testDecrement() {
        var item = CounterButtonItem(name: "Pushups", displayCount: 5)
        item.decrement()
        XCTAssertEqual(item.displayCount, 4)
    }

    func testDecrementCanGoNegative() {
        var item = CounterButtonItem(name: "Score", displayCount: 0)
        item.decrement()
        XCTAssertEqual(item.displayCount, -1)
    }

    func testDoubleTapZeroesThenRestores() {
        var item = CounterButtonItem(name: "Laps", displayCount: 7)

        item.toggleZero()
        XCTAssertEqual(item.displayCount, 0)
        XCTAssertTrue(item.isZeroed)
        XCTAssertEqual(item.savedValue, 7)

        item.toggleZero()
        XCTAssertEqual(item.displayCount, 7)
        XCTAssertFalse(item.isZeroed)
    }

    func testDoubleTapAlternatesAcrossMultipleCycles() {
        var item = CounterButtonItem(name: "Laps", displayCount: 3)

        item.toggleZero() // zero -> 0 (saved 3)
        item.increment()  // 1 (still counts up while zeroed)
        item.toggleZero() // restore -> 3 (the value from before zeroing)
        XCTAssertEqual(item.displayCount, 3)
        XCTAssertFalse(item.isZeroed)

        item.increment()  // 4
        item.toggleZero() // zero -> 0 (saved 4)
        XCTAssertEqual(item.displayCount, 0)
        XCTAssertEqual(item.savedValue, 4)
        XCTAssertTrue(item.isZeroed)

        item.toggleZero() // restore -> 4
        XCTAssertEqual(item.displayCount, 4)
        XCTAssertFalse(item.isZeroed)
    }
}

