//
//  PhoneConnectivityManager.swift
//  TapCounter
//
//  Keeps the iPhone's CounterStore in sync with the paired Watch app via
//  WatchConnectivity. Sends the full button list whenever it changes
//  locally, and applies whatever the watch last sent.
//

import Foundation
import WatchConnectivity

@Observable
final class PhoneConnectivityManager: NSObject, WCSessionDelegate {
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
        guard let data = try? JSONEncoder().encode(buttons) else {
            print("Send, unable to encode buttons, buttons \(buttons.isEmpty ? "is" : "is not") empty")
            return
        }
        try? WCSession.default.updateApplicationContext(["buttons": data])
    }

   // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Push current state to the watch as soon as the session is ready,
        // so a newly installed watch app has something to show right away.
        print("Session activated, sending store.buttons to remote, it \(store.buttons.isEmpty ? "is" : "is not") empty")
        send(store.buttons)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for the next paired watch, per Apple's guidance.
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["buttons"] as? Data, let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.store.applyUpdatedButtons(decoded)
            }
        }
    }
}

