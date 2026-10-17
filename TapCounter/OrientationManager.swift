//
//  OrientationManager.swift
//  TapCounter
//
//  Created by Bill Snook on 10/14/26.
//

import SwiftUI
import Combine

class OrientationManager: ObservableObject {
    @Published var orientation: UIDeviceOrientation = .unknown

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize with current orientation
        self.orientation = UIDevice.current.orientation

        // Subscribe to changes
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .map { _ in UIDevice.current.orientation }
            .sink { [weak self] newOrientation in
                self?.orientation = newOrientation
            }
            .store(in: &cancellables)
    }

    var isLandscape: Bool {
        return !orientation.isPortrait
    }
}
