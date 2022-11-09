//
// Created by DOYEON BAEK on 2022/10/26.
//

import Foundation
import WebRTC


class SensorEvent {
    public var values: [Float]
    public var accuracy: Int
    public var timestamp: Int64

    public init() {
        self.values = [0, 0, 0]
        self.accuracy = 0
        self.timestamp = 0
    }

    public init(values: [Float], accuracy: Int, timestamp: Int64) {
        self.values = values
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
}

protocol SensorEventListener {
    func onSensorChanged(event: SensorEvent)
    func onAccuracyChanged()
}

class ThreadUtils {
    private static var currentThread: Thread? = Thread.current

    public init() {
    }

    public static func checkIsOnValidThread() {
        if currentThread == nil {
            currentThread = Thread.current
        }

        if !(currentThread == Thread.current) {
            print("This method must be called on the same thread as the constructor.")
        }
    }

    public static func detachThread() {
        currentThread = nil
    }
}

class AppRTCProximitySensor {

    private var threadChecker: ThreadUtils = ThreadUtils()
    private var onSensorStateListener: Runnable?
    private var lastStateReportIsNear: Bool?

    static func create(sensorStateListener: @escaping Runnable) -> AppRTCProximitySensor {
        return AppRTCProximitySensor(sensorStateListener: sensorStateListener)
    }

    private init(sensorStateListener: @escaping Runnable) {
        onSensorStateListener = sensorStateListener
    }

    public func start() -> Bool {
        ThreadUtils.checkIsOnValidThread()
        print("start \(AppRTCUtils.getThreadInfo())")
        UIDevice.current.isProximityMonitoringEnabled = true
        if UIDevice.current.isProximityMonitoringEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(onAccuracyChanged), name: Notification.Name.myNotificationKeyProximity, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(onSensorChanged), name: Notification.Name.myNotificationKeyProximity, object: nil)
        }
        logProximitySensorInfo()
        return true
    }

    public func stop() {
        ThreadUtils.checkIsOnValidThread()
        print("stop \(AppRTCUtils.getThreadInfo())")
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self, name: Notification.Name.myNotificationKeyProximity, object: nil)
    }

    private func logProximitySensorInfo() {
        print("Proximity sensor: " + (UIDevice.current.isProximityMonitoringEnabled ? "enabled" : "disabled"))
        print("Proximity sensor: " + (UIDevice.current.proximityState ? "near" : "far"))
    }

    public func sensorReportsNearState() -> Bool {
        ThreadUtils.checkIsOnValidThread()
        if let lastStateReportIsNear = lastStateReportIsNear {
            return lastStateReportIsNear
        }
        return UIDevice.current.proximityState
    }

    @objc func onAccuracyChanged() {
        ThreadUtils.checkIsOnValidThread()

        if UIDevice.current.proximityState {
            print("Proximity sensor => NEAR state")
        } else {
            print("Proximity sensor => FAR state")
        }
    }

    @objc func onSensorChanged() {
        ThreadUtils.checkIsOnValidThread()

        if UIDevice.current.proximityState {
            print("Proximity sensor => NEAR state")
            lastStateReportIsNear = true
        } else {
            print("Proximity sensor => FAR state")
            lastStateReportIsNear = false
        }

        if let onSensorStateListener = onSensorStateListener {
            onSensorStateListener()
        }

//        print("onSensorChanged: accuracy=\(event.accuracy) timestamp=\(event.timestamp) values= \(event.values[0])")
    }
}
