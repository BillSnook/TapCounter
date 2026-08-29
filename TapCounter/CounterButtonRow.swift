//
//  CounterButtonRow.swift
//  TapCounter
//
//  The functional button itself: name + a prominent count. Gestures:
//    - tap:         increment
//    - long press:  decrement
//    - double tap:  zero the value, or (on the next double tap) restore it
//

import SwiftUI

struct CounterButtonRow: View {
    @Environment(CounterStore.self) private var store
    let item: CounterButtonItem

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                if item.isZeroed {
                    Label("Zeroed — triple tap to restore", systemImage: "arrow.uturn.backward")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(item.count)))
                    .animation(.snappy, value: item.count)
                    .frame(minWidth: 72, alignment: .trailing)
                    .foregroundStyle(item.isZeroed ? .secondary : .primary)
                if item.resetsDaily {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                } else {
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .scaleEffect(isPressed ? 0.97 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Order matters: SwiftUI disambiguates single vs. double tap when
        // both are attached to the same view.
        .onTapGesture(count: 1) {
            store.increment(id: item.id)
            bump()
        }
        .onTapGesture(count: 2) {
            store.decrement(id: item.id)
            bump()
        }
        .onTapGesture(count: 3) {
            store.toggleZero(id: item.id)
            bump()
        }
//        .accessibilityElement(children: .combine)
//        .accessibilityLabel("\(item.name), count \(item.count)")
//        .accessibilityHint("Tap to increment. Double tap to decrement. Triple tap to zero or restore.")
    }

    private func bump() {
        withAnimation(.easeOut(duration: 0.08)) { isPressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.08)) { isPressed = false }
        }
    }
}

#Preview {
    List {
        CounterButtonRow(item: CounterButtonItem(name: "Pushups", count: 12))
        CounterButtonRow(item: CounterButtonItem(name: "Laps", count: 0))
    }
    .environment(CounterStore())
}

