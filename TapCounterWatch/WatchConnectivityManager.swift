//
//  WatchConnectivityManager.swift
//  TapCounterWatch
//
//  Watch-side counterpart to PhoneConnectivityManager: keeps this device's
//  CounterStore in sync with the iPhone via WatchConnectivity.
//

import Foundation
import WatchConnectivity

@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    private let store: CounterStore

    init(store: CounterStore) {
        self.store = store
        super.init()
        store.onLocalChange = { [weak self] buttons in
            self?.send(buttons)
        }
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func send(_ buttons: [CounterButtonItem]) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(buttons) else { return }
        try? WCSession.default.updateApplicationContext(["buttons": data])
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["buttons"] as? Data,
              let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.store.applyRemoteUpdate(decoded)
        }
    }
}

