//
//  WatchCounterListView.swift
//  TapCounterWatch
//
//  Displays the same functional buttons created on the iPhone. Lives as one
//  page of WatchContentView's paging TabView; see WatchContentView.
//

import SwiftUI

struct WatchCounterListView: View {
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
            .navigationTitle("Count List")
            .onAppear {     // Closure should complete before any rendered frames appear
                store.cleanEvents()
            }
        }
    }
}

#Preview {
    WatchCounterListView()
        .environment(CounterStore())
}
