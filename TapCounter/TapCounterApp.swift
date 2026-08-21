//
//  TapCounterApp.swift
//  TapCounter
//

import SwiftUI

@main
struct TapCounterApp: App {
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
    }
}

