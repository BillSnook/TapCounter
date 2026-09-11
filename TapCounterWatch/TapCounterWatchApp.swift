//
//  TapCounterWatchApp.swift
//  TapCounterWatch
//

import SwiftUI

@main
struct TapCounterWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.cleanEvents()
            }
        }
    }
}

