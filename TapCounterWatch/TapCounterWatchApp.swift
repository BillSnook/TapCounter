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
                print("**   TapCounterwatchApp (main), .onChange to active, \(store.buttons.count) buttons")
//                store.cleanEvents()
            } else if newPhase == .inactive {
                print("**   TapCounterwatchApp (main), .onChange to inactive")
            } else if newPhase == .background {
                print("**   TapCounterwatchApp (main), .onChange to background")
            } else  {
                print("**   TapCounterwatchApp (main), .onChange to ?")
            }
        }
    }
}

