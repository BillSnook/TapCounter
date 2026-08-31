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

            HStack(spacing: 0) {
                Text("Today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .foregroundStyle(.opacity(0))   // Hide it, used as placeholder for now to center count
                    .frame(width: 45)
                Spacer(minLength: 2)
                Text("\(item.count)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(item.count)))
                    .animation(.snappy, value: item.count)
                    .foregroundStyle(item.isZeroed ? .secondary : .primary)
                Spacer(minLength: 2)
                Text(item.resetsDaily ? "Today" : "Total")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 45)
           }
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
            store.toggleZero(id: item.id)
        }
//        .onLongPressGesture(minimumDuration: 0.5) {   // Works but is redundant
//    Maybe trigger showing a chart for this button's data
//        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), count is \(item.count)")
    }
}

#Preview {
    List {
        WatchCounterButtonRow(item: CounterButtonItem(name: "Pushups", count: 12))
    }
    .environment(CounterStore())
}

