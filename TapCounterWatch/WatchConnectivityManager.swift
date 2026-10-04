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
        store.onButtonChanges = { [weak self] buttons in
            self?.send(buttons)
        }
        store.onStatusChanges = { [weak self] buttons in
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

    private func send(_ statusMsg: RemoteStatusMessage) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            print("Send, unable to send buttons, session state is inactive")
            return
        }
        guard let data = try? JSONEncoder().encode(statusMsg) else {
            print("Send, unable to encode status data, status message: \(statusMsg.statusMessage)")
            return
        }
        try? WCSession.default.updateApplicationContext(["status": data])
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["buttons"] as? Data {
            guard let decoded = try? JSONDecoder().decode([CounterButtonItem].self, from: data) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.store.receivedButtonsUpdate(decoded)
            }
        } else if let data = applicationContext["status"] as? Data {
            guard let decoded = try? JSONDecoder().decode(RemoteStatusMessage.self, from: data) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.store.receivedStatusUpdate(decoded)
            }
        }
    }
}

