//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation
import UIKit

class BatteryManager {
    private var batteryLevel: Float = 0.0
    private var batteryState: UIDevice.BatteryState = .unknown
    private var batteryLevelObserver: NSObjectProtocol?
    private var batteryStateObserver: NSObjectProtocol?
    private var batteryLevelCallback: ((Float) -> Void)?
    private var batteryStateCallback: ((UIDevice.BatteryState) -> Void)?

    init() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        batteryLevelObserver = NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            self.batteryLevel = UIDevice.current.batteryLevel
            self.batteryLevelCallback?(self.batteryLevel)
        }
        batteryStateObserver = NotificationCenter.default.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            self.batteryState = UIDevice.current.batteryState
            self.batteryStateCallback?(self.batteryState)
        }
    }

    deinit {
        if let batteryLevelObserver = batteryLevelObserver {
            NotificationCenter.default.removeObserver(batteryLevelObserver)
        }
        if let batteryStateObserver = batteryStateObserver {
            NotificationCenter.default.removeObserver(batteryStateObserver)
        }
    }

    func getBatteryLevel() -> Float {
        return batteryLevel
    }

    func getBatteryState() -> UIDevice.BatteryState {
        return batteryState
    }

    func setBatteryLevelCallback(callback: ((Float) -> Void)?) {
        batteryLevelCallback = callback
    }

    func setBatteryStateCallback(callback: ((UIDevice.BatteryState) -> Void)?) {
        batteryStateCallback = callback
    }

    func isCharging() -> Bool {
        return batteryState == .charging || batteryState == .full
    }
}
