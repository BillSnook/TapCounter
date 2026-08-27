//
//  WatchCounterButtonRow.swift
//  TapCounterWatch
//
//  Same gesture behavior as the iPhone row, laid out for a watch screen:
//    - tap:         increment
//    - double tap:  decrement
//    - triple tap:  zero the value, or restore it on the next triple tap
//

import SwiftUI

struct WatchCounterButtonRow: View {
    @Environment(CounterStore.self) private var store
    let item: CounterButtonItem

    var body: some View {
        VStack(spacing: 2) {
            Text(item.name)
                .font(.footnote)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text("\(item.count)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(item.count)))
                .animation(.snappy, value: item.count)
                .foregroundStyle(item.isZeroed ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 1) {
            store.increment(id: item.id)
        }
        .onTapGesture(count: 2) {
            store.decrement(id: item.id)
        }
        .onTapGesture(count: 3) {
//        .onLongPressGesture(minimumDuration: 0.5) {
            store.toggleZero(id: item.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), count \(item.count)")
    }
}

#Preview {
    List {
        WatchCounterButtonRow(item: CounterButtonItem(name: "Pushups", count: 12))
    }
    .environment(CounterStore())
}

