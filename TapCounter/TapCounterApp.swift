//
//  TapCounterApp.swift
//  TapCounter
//

import SwiftUI

@main
struct TapCounterApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = CounterStore()
    @State private var connectivity: PhoneConnectivityManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(store)
            .onAppear {
                if connectivity == nil {
                    connectivity = PhoneConnectivityManager(store: store)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("TapCounterApp (main), .onChange to active, \(store.buttons.count) buttons")
                store.cleanEvents()
//                for button in store.buttons {
//                    print("TapCounterApp .onChange to active, after store.cleanEvents, \(button.name) has \(button.events.count) events, count of \(button.count)")
//                }
            }
        }
    }
}

