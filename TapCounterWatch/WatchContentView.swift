//
//  WatchContentView.swift
//  TapCounterWatch
//
//  Displays the same functional buttons created on the iPhone.
//

import SwiftUI

struct WatchContentView: View {
    @Environment(CounterStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                if store.buttons.isEmpty {
                    Text("Create buttons on your iPhone to see them here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.buttons) { item in
                        WatchCounterButtonRow(item: item)
                    }
                }
            }
            .padding(.horizontal, 8)
            .navigationTitle("CounterList")
        }
    }
}

#Preview {
    WatchContentView()
        .environment(CounterStore())
}

