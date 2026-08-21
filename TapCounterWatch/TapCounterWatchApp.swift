//
//  TapCounterWatchApp.swift
//  TapCounterWatch
//

import SwiftUI

@main
struct TapCounterWatchApp: App {
    @State private var store = CounterStore()
    @State private var connectivity: WatchConnectivityManager?

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(store)
                .onAppear {
                    if connectivity == nil {
                        connectivity = WatchConnectivityManager(store: store)
                    }
                }
        }
    }
}

