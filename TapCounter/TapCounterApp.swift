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
    @StateObject var orientationManager = OrientationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(store)
            .environmentObject(orientationManager)
            .onAppear {
                if connectivity == nil {
                    connectivity = PhoneConnectivityManager(store: store)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("\n \(formatDate()) * TapCounterApp (main), .onChange to active, \(store.buttons.count) buttons")
                store.checkEvents()
            } else if newPhase == .inactive {
                print(" \(formatDate()) * TapCounterApp (main), .onChange to inactive")
            } else if newPhase == .background {
                print(" \(formatDate()) * TapCounterApp (main), .onChange to background")
            } else  {
                print(" \(formatDate()) * TapCounterApp (main), .onChange to ?")
            }
        }
    }
}

