//
//  CounterButtonItemTests.swift
//  TapCounterTests
//

import XCTest
@testable import TapCounter

final class CounterButtonItemTests: XCTestCase {

    func testIncrement() {
        var item = CounterButtonItem(name: "Pushups", count: 5)
        item.increment()
        XCTAssertEqual(item.count, 6)
    }

    func testDecrement() {
        var item = CounterButtonItem(name: "Pushups", count: 5)
        item.decrement()
        XCTAssertEqual(item.count, 4)
    }

    func testDecrementCanGoNegative() {
        var item = CounterButtonItem(name: "Score", count: 0)
        item.decrement()
        XCTAssertEqual(item.count, -1)
    }

    func testDoubleTapZeroesThenRestores() {
        var item = CounterButtonItem(name: "Laps", count: 7)

        item.toggleZero()
        XCTAssertEqual(item.count, 0)
        XCTAssertTrue(item.isZeroed)
        XCTAssertEqual(item.savedValue, 7)

        item.toggleZero()
        XCTAssertEqual(item.count, 7)
        XCTAssertFalse(item.isZeroed)
    }

    func testDoubleTapAlternatesAcrossMultipleCycles() {
        var item = CounterButtonItem(name: "Laps", count: 3)

        item.toggleZero() // zero -> 0 (saved 3)
        item.increment()  // 1 (still counts up while zeroed)
        item.toggleZero() // restore -> 3 (the value from before zeroing)
        XCTAssertEqual(item.count, 3)
        XCTAssertFalse(item.isZeroed)

        item.increment()  // 4
        item.toggleZero() // zero -> 0 (saved 4)
        XCTAssertEqual(item.count, 0)
        XCTAssertEqual(item.savedValue, 4)
        XCTAssertTrue(item.isZeroed)

        item.toggleZero() // restore -> 4
        XCTAssertEqual(item.count, 4)
        XCTAssertFalse(item.isZeroed)
    }
}

