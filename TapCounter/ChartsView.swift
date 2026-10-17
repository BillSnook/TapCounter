//
//  ChartsView.swift
//  TapCounter
//
//  The "Charts" tab -- will chart each button's tap history (from
//  TapEvents) by day/time.
//

import SwiftUI
import Charts

struct ChartsView: View {
    @Environment(CounterStore.self) private var store
    @EnvironmentObject var orientationInfo: OrientationManager

    var body: some View {
        NavigationStack {
//            List {
                if store.buttons.isEmpty {
                    Text("Create buttons first to see them here.")
                        .font(.title)
                        .foregroundStyle(.foreground)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                } else {
                    if orientationInfo.orientation.isPortrait  && orientationInfo.orientation.isValidInterfaceOrientation {
                        ForEach(store.buttons) { button in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(button.name)")
                                    .font(.title2.monospacedDigit())
                                //                                .alignment(.leading)
                                ForEach(button.events) { event in
                                    HStack() {
                                        Text("\(event.displayCount)")
                                            .font(.headline.monospacedDigit())
                                        Spacer(minLength: 4)
                                        Text("\(formatMonthDate(event.timestamp))")
                                            .font(.headline.monospacedDigit())
                                    }
                                    //                                .padding(.vertical, 4)
                                }
                            }
                            .padding(16)
                        }
                    }
                    Chart(store.buttons) { button in
                        ForEach(button.events) { event in
                            PointMark(
                                x: .value("Day", event.timestamp, unit: .minute),
                                y: .value("Count", event.displayCount)
                            )
                            .foregroundStyle(.teal.gradient)
                        }
                    }
                    .padding(10)
                }
//            }
//            .padding(.horizontal, 8)
//            .navigationTitle("Tap Count Charts")
        }
    }
//    func returnReversed(_ inputArray: [TapEvent]) -> [TapEvent] {
//        let newList = inputArray.sorted { $0.timestamp < $1.timestamp }
//        return newList
//    }
}

#Preview {
    ChartsView()
        .environment(CounterStore())
}
