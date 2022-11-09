//
// Created by DOYEON BAEK on 2022/10/26.
//

import Foundation
import CoreBluetooth
import ExternalAccessory
import AVFoundation

enum BluetoothManagerState {
    case UNINITIALIZED
    case ERROR
    case HEADSET_UNAVAILABLE
    case HEADSET_AVAILABLE
    case SCO_DISCONNECTING
    case SCO_CONNECTING
    case SCO_CONNECTED
}

enum BluetoothHeadset: String {
    case EXTRA_STATE = "ios.bluetooth.profile.extra.STATE"
    case ACTION_CONNECTION_STATE_CHANGED = "ios.bluetooth.headset.profile.action.CONNECTION_STATE_CHANGED"
    case ACTION_AUDIO_STATE_CHANGED = "ios.bluetooth.headset.profile.action.AUDIO_STATE_CHANGED"
    case ACTION_ACTIVE_DEVICE_CHANGED = "ios.bluetooth.headset.profile.action.ACTIVE_DEVICE_CHANGED"
    case ACTION_VENDOR_SPECIFIC_HEADSET_EVENT = "ios.bluetooth.headset.action.VENDOR_SPECIFIC_HEADSET_EVENT"
    case EXTRA_VENDOR_SPECIFIC_HEADSET_EVENT_CMD = "ios.bluetooth.headset.extra.VENDOR_SPECIFIC_HEADSET_EVENT_CMD"
    case EXTRA_VENDOR_SPECIFIC_HEADSET_EVENT_CMD_TYPE = "ios.bluetooth.headset.extra.VENDOR_SPECIFIC_HEADSET_EVENT_CMD_TYPE"
}

enum BluetoothHeadsetState: Int {
    case STATE_DISCONNECTED = 0
    case STATE_CONNECTING = 1
    case STATE_CONNECTED = 2
    case STATE_DISCONNECTING = 3
    case STATE_AUDIO_DISCONNECTED = 10
    case STATE_AUDIO_CONNECTING = 11
    case STATE_AUDIO_CONNECTED = 12
}

class AppRTCBluetoothManager: NSObject {
    private static var MAX_SCO_CONNECTION_ATTEMPTS = 2
    private var isBluetoothHeadsetConnected: Bool {
        !AVAudioSession.sharedInstance().currentRoute.outputs.compactMap {
                    ($0.portType == .bluetoothA2DP ||
                            $0.portType == .bluetoothHFP ||
                            $0.portType == .bluetoothLE) ? true : nil
                }
                .isEmpty
    }
    private static var BLUETOOTH_SCO_TIMEOUT_MS = 4000
    // Maximum number of SCO connection attempts.
    private var apprtcAudioManager: AppRTCAudioManager?
    private var handler: NotificationCenter?

    var scoConnectionAttempts: Int?
    public var bluetoothState: BluetoothManagerState?
    private var bluetoothManager: CBManager?
    private var bluetoothHeadset: CBPeripheral?

    private var threadChecker: ThreadUtils = ThreadUtils()

    private var discoveredPeripherals: Set<CBPeripheral> = []
    private lazy var bluetoothHeadsetReceiver: BroadcastReceiver = BroadcastReceiver()

    @objc private func bluetoothTimeoutRunnable() {
        bluetoothTimeout()
    }


    override public init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }

    private class BluetoothHeadsetBroadcastReceiver: BroadcastReceiver {
        var context: AppRTCBluetoothManager

        public init(context: AppRTCBluetoothManager) {
            self.context = context
        }

        override func onReceive(handler: @escaping (Intent) -> Void) {
            if context.bluetoothState == BluetoothManagerState.UNINITIALIZED {
                return
            }
            if let intent {
                var myHandler = { [self] (intent: Intent) in
                    var action = intent.getAction()
                    var data = intent.getData()
                    if action == BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED.rawValue {
                        context.scoConnectionAttempts = 0
                        context.updateAudioDeviceState()
                        if let state = data[BluetoothHeadset.EXTRA_STATE.rawValue] as? Int {
                            if state == BluetoothHeadsetState.STATE_CONNECTED.rawValue {
                                context.scoConnectionAttempts = 0
                                context.updateAudioDeviceState()
                            } else if state == BluetoothHeadsetState.STATE_CONNECTING.rawValue {
                            } else if state == BluetoothHeadsetState.STATE_DISCONNECTING.rawValue {
                            } else if state == BluetoothHeadsetState.STATE_DISCONNECTED.rawValue {
                                context.startScoAudio()
                                context.updateAudioDeviceState()
                            }
                        }
                    } else if action == BluetoothHeadset.ACTION_AUDIO_STATE_CHANGED.rawValue {
                        if let state = data[BluetoothHeadset.EXTRA_STATE.rawValue] as? Int {
                            if state == BluetoothHeadsetState.STATE_AUDIO_CONNECTED.rawValue {
                                context.cancelTimer()
                                context.bluetoothState = BluetoothManagerState.SCO_CONNECTED
                                context.scoConnectionAttempts = 0
                                context.updateAudioDeviceState()
                            } else if state == BluetoothHeadsetState.STATE_AUDIO_CONNECTING.rawValue {
                                print("+++ Bluetooth audio SCO is now connecting...")
                            } else if state == BluetoothHeadsetState.STATE_AUDIO_DISCONNECTED.rawValue {
                                print("+++ Bluetooth audio SCO is now disconnected")
                                context.updateAudioDeviceState()
                            } else {
                                print("Unexpected state BluetoothHeadset.STATE_AUDIO_CONNECTED")
                            }
                        }
                    }
                }
                super.onReceive(handler: myHandler)
            }
        }
    }

    static func create(audioManager: AppRTCAudioManager) -> AppRTCBluetoothManager {
        return AppRTCBluetoothManager(audioManager: audioManager)
    }

    convenience private init(audioManager: AppRTCAudioManager) {
        self.init()
        ThreadUtils.checkIsOnValidThread()
        self.apprtcAudioManager = audioManager
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        bluetoothState = BluetoothManagerState.UNINITIALIZED
        bluetoothHeadsetReceiver = BluetoothHeadsetBroadcastReceiver(context: self)
        handler = NotificationCenter.default
        handler?.addObserver(self, selector: #selector(bluetoothTimeoutRunnable), name: Notification.Name.myNotificationKeyBluetooth, object: nil)
    }

    public func getState() -> BluetoothManagerState {
        if let bluetoothState = bluetoothState {
            return bluetoothState
        }
        return BluetoothManagerState.UNINITIALIZED
    }

    public func start() {
        ThreadUtils.checkIsOnValidThread()
        if bluetoothState != BluetoothManagerState.UNINITIALIZED {
            return
        }
        scoConnectionAttempts = 0
        logBluetoothAdapterInfo()

        class MyIntentFilter: IntentFilter {
            var id = "MyIntentFilter"
            var action: [String] = []

            func onReceive(intent: Intent) {
            }

            func getAction() -> [String] {
                return action
            }

            func addAction(action: String) {
                self.action.append(action)
            }
        }

        var bluetoothHeadsetFilter = MyIntentFilter()
        bluetoothHeadsetFilter.addAction(action: BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED.rawValue)
        bluetoothHeadsetFilter.addAction(action: BluetoothHeadset.ACTION_AUDIO_STATE_CHANGED.rawValue)
        bluetoothHeadsetReceiver.registerIntentFilter(intentFilter: bluetoothHeadsetFilter)
        bluetoothState = BluetoothManagerState.HEADSET_UNAVAILABLE
    }

    public func stop() {
        ThreadUtils.checkIsOnValidThread()
        print("stop, BT state = \(bluetoothState)")
        stopScoAudio()
        if bluetoothState == BluetoothManagerState.UNINITIALIZED {
            return
        }
        bluetoothHeadsetReceiver.unregisterReceiver()
        cancelTimer()
        if isBluetoothHeadsetConnected {
            bluetoothHeadset = nil
        }
        bluetoothState = BluetoothManagerState.UNINITIALIZED
        print("stop done: BT state = \(bluetoothState)")
    }

    public func startScoAudio() -> Bool {
        ThreadUtils.checkIsOnValidThread()
        if let scoConnectionAttempts, scoConnectionAttempts >= AppRTCBluetoothManager.MAX_SCO_CONNECTION_ATTEMPTS {
            return false
        }
        if bluetoothState == BluetoothManagerState.HEADSET_AVAILABLE {
            return false
        }
        bluetoothState = BluetoothManagerState.SCO_CONNECTING
        scoConnectionAttempts! += 1
        startTimer()
        print("startScoAudio done: BT state = \(bluetoothState)")
        return true
    }

    public func stopScoAudio() {
        ThreadUtils.checkIsOnValidThread()
        if bluetoothState == BluetoothManagerState.SCO_CONNECTING && bluetoothState != BluetoothManagerState.SCO_CONNECTED {
            return
        }
        cancelTimer()
        bluetoothState = BluetoothManagerState.SCO_DISCONNECTING
        print("stopScoAudio done: BT state = \(bluetoothState), SCO is on : \(isScoOn())")
    }

    public func updateDevice() {
        if bluetoothState == BluetoothManagerState.UNINITIALIZED || bluetoothHeadset == nil {
            return
        }
        print("updateDevice")
        // get bluetooth bonded device
        if isBluetoothHeadsetConnected {
            bluetoothState = BluetoothManagerState.HEADSET_AVAILABLE
            print("connected bluetooth headset: \(bluetoothHeadset)")
        } else {
            bluetoothHeadset = nil
            bluetoothState = BluetoothManagerState.HEADSET_UNAVAILABLE
            print("no connected bluetooth headset")
        }
        print("updateDevice done: BT state = \(bluetoothState)")
    }


    private func updateAudioDeviceState() {
        ThreadUtils.checkIsOnValidThread()
        print("updateAudioDeviceState")
        if let apprtcAudioManager = apprtcAudioManager {
            apprtcAudioManager.updateAudioDeviceState()
        }
    }

/** Starts timer which times out after BLUETOOTH_SCO_TIMEOUT_MS milliseconds. */
    private func startTimer() {
        ThreadUtils.checkIsOnValidThread()
        print("startTimer")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: {
            self.handler?.post(Notification(name: Notification.Name.myNotificationKeyBluetooth))
        })
    }

/** Cancels any outstanding timer tasks. */
    private func cancelTimer() {
        ThreadUtils.checkIsOnValidThread()
        print("cancelTimer")
        handler?.removeObserver(self, name: Notification.Name.myNotificationKeyBluetooth, object: nil)
    }


    private func bluetoothTimeout() {
        ThreadUtils.checkIsOnValidThread()
        if let bluetoothManager {
            var state = bluetoothManager.state
            if state == CBManagerState.unsupported || state == CBManagerState.unauthorized || state == CBManagerState.poweredOff {
                return
            }
            print("bluetoothTimeout: BT state= \(state), attempts: \(scoConnectionAttempts), SCO is on:  \(isScoOn())")

            var scoConnected = false
            var devices = EAAccessoryManager.shared().connectedAccessories
            if devices.count > 0 {
                var bluetoothDevice = devices[0]
                // Check if the connected device is a headset.
                if isBluetoothHeadsetConnected {
                    print("SCO connected with headset: \(bluetoothDevice.name)")
                    scoConnected = true
                } else {
                    print("SCO connected with non-headset: \(bluetoothDevice.name)")
                }
            }
            if scoConnected {
                bluetoothState = BluetoothManagerState.SCO_CONNECTED
                scoConnectionAttempts = 0
            } else {
                print("BT failed to connect after timeout")
                stopScoAudio()
            }
            updateAudioDeviceState()
            print("bluetoothTimeout done : BT state = \(state)")
        }
    }

    // sco: Synchronous Connection-Oriented, 동기식 접속 지향 링크

    private func isScoOn() -> Bool {
        return apprtcAudioManager?.amState == AudioManagerState.RUNNING
    }

    private func stateToString(state: CBManagerState) -> String {
        switch state {
        case CBManagerState.unauthorized:
            return "UNAUTHORIZED"
        case CBManagerState.poweredOff:
            return "POWERED_OFF"
        case CBManagerState.poweredOn:
            return "POWERED_ON"
        case CBManagerState.resetting:
            return "RESETTING"
        case CBManagerState.unsupported:
            return "UNSUPPORTED"
        default:
            return "UNKNOWN"
        }
    }

    private func logBluetoothAdapterInfo() {
        print("BluetoothAdapter: enabled=\(bluetoothState == BluetoothManagerState.HEADSET_AVAILABLE), state=\(bluetoothState), name=\(bluetoothManager?.description)")
    }
}

extension AppRTCBluetoothManager: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth state changed: unknown")
        case .resetting:
            print("Bluetooth state changed: resetting")
        case .unsupported:
            print("Bluetooth state changed: unsupported")
        case .unauthorized:
            print("Bluetooth state changed: unauthorized")
        case .poweredOff:
            print("Bluetooth state changed: powered off")
        case .poweredOn:
            print("Bluetooth state changed: powered on")
            central.scanForPeripherals(withServices: nil)
        @unknown default:
            print("Bluetooth state changed: unknown")
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if !isBluetoothHeadsetConnected {
            stopScoAudio()
            bluetoothHeadset = nil
            bluetoothState = BluetoothManagerState.HEADSET_UNAVAILABLE
            updateAudioDeviceState()
            print("onServiceDisconnected: BT state = \(bluetoothState)")
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Bluetooth device connected")
        if !isBluetoothHeadsetConnected {
            bluetoothHeadset = peripheral
            updateAudioDeviceState()
            if let bluetoothManager {
                print("onServiceConnected: BT state = \(bluetoothManager.state)")
            }
        } else {
            return
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        discoveredPeripherals.insert(peripheral)
    }
}

extension AppRTCBluetoothManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Bluetooth device discovered services")
    }
}