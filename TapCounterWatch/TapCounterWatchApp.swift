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
                print("\n \(formatDate()) * TapCounterWatchApp (main), .onChange to active, \(store.buttons.count) buttons - cleanDaily")
                store.cleanDaily()
            } else if newPhase == .inactive {
                print(" \(formatDate()) * TapCounterWatchApp (main), .onChange to inactive")
            } else if newPhase == .background {
                print(" \(formatDate()) * TapCounterWatchApp (main), .onChange to background\n")
            } else  {
                print(" \(formatDate()) * TapCounterWatchApp (main), .onChange to ?")
            }
        }
    }
}

