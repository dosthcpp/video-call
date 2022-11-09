//
// Created by DOYEON BAEK on 2022/10/26.
//

import Foundation
import AVFAudio
import CoreTelephony
import UIKit

enum AudioDevice {
    case SPEAKER_PHONE
    case WIRED_HEADSET
    case EARPIECE
    case BLUETOOTH
    case NONE
}

enum AudioManagerState {
    case UNINITIALIZED
    case PREINITIALIZED
    case RUNNING
}

enum AudioManagerStateAudioFocus: Int {
    case AUDIOFOCUS_NONE = 0
    case AUDIOFOCUS_GAIN = 1
    case AUDIOFOCUS_GAIN_TRANSIENT = 2
    case AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK = 3
    case AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE = 4
    case AUDIOFOCUS_LOSS = -1
    case AUDIOFOCUS_LOSS_TRANSIENT = -2
    case AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = -3
}

protocol AudioManagerEvents {
    func onAudioDeviceChanged(selectedAudioDevice: AudioDevice, availableAudioDevices: [AudioDevice])
}

protocol OnAudioFocusChangeListener {
    func onAudioFocusChange(focusChange: Int)
}

class AppRTCAudioManager {
    public static var SPEAKERPHONE_AUTO = "auto"
    public static var SPEAKERPHONE_TRUE = "true"
    public static var SPEAKERPHONE_FALSE = "false"

    private var audioManager: AVAudioSession?

    private var audioManagerEvents: AudioManagerEvents?
    public var amState: AudioManagerState?
    private var savedAudioMode = AVAudioSession.Mode.default
    private var savedIsSpeakerPhoneOn: Bool?
    private var savedIsMicrophoneMuted: Bool?
    private var hasWiredHeadset: Bool?

    private var defaultAudioDevice: AudioDevice?
    private var selectedAudioDevice: AudioDevice?
    private var userSelectedAudioDevice: AudioDevice?

    private var useSpeakerPhone: String?
    private var proximitySensor: AppRTCProximitySensor?
    private var bluetoothManager: AppRTCBluetoothManager?

    private var audioDevices: Set<AudioDevice> = Set()

    private var wiredHeadsetReceiver: BroadcastReceiver?

    private var audioFocusChangeListener: OnAudioFocusChangeListener?

    private func onProximitySensorChangedState() {
        if !(useSpeakerPhone == AppRTCAudioManager.SPEAKERPHONE_AUTO) {
            return
        }

        if audioDevices.count == 2 && audioDevices.contains(AudioDevice.EARPIECE) && audioDevices.contains(AudioDevice.SPEAKER_PHONE) {
            if let near = proximitySensor?.sensorReportsNearState() as? Bool {
                if near {
                    setAudioDeviceInternal(device: AudioDevice.EARPIECE)
                } else {

                    setAudioDeviceInternal(device: AudioDevice.SPEAKER_PHONE)
                }
            }
        }
    }

    private class WiredHeadsetReceiver: BroadcastReceiver {
        private static var STATE_UNPLUGGED = 0
        private static var STATE_PLUGGED = 1
        private static var HAS_NO_MIC = 0
        private static var HAS_MIC = 1
        private var context: AppRTCAudioManager

        public init(context: AppRTCAudioManager) {
            self.context = context
        }

        override public func onReceive(handler: @escaping (Intent) -> Void) {
            if let intent = intent {
                var myHandler = {[self] (intent: Intent) in
                    let data = intent.getData()
                    if let state = data["state"] as? Int, let microphone = data["microphone"] as? Int, let name = data["name"] as? String {
                        print("WiredHeadsetReceiver.onReceive : \(AppRTCUtils.getThreadInfo()), a= \(intent.getAction()), s=\((state == WiredHeadsetReceiver.STATE_UNPLUGGED ? "unplugged" : "plugged")), m=\((microphone == WiredHeadsetReceiver.HAS_MIC ? "mic" : "no mic")), n=\(name)")
                        context.hasWiredHeadset = (state == WiredHeadsetReceiver.STATE_PLUGGED)
                        context.updateAudioDeviceState()
                    }
                }
                super.onReceive(handler: myHandler)
            }
        }
    }

    public static func create() -> AppRTCAudioManager {
        return AppRTCAudioManager()
    }

    private init() {
        ThreadUtils.checkIsOnValidThread()
        audioManager = AVAudioSession.sharedInstance()
        bluetoothManager = AppRTCBluetoothManager.create(audioManager: self)
        wiredHeadsetReceiver = WiredHeadsetReceiver(context: self)
        amState = AudioManagerState.UNINITIALIZED

        let preferences = UserDefaults.standard
        useSpeakerPhone = preferences.string(forKey: "use_speakerphone")
        if useSpeakerPhone == AppRTCAudioManager.SPEAKERPHONE_FALSE {
            defaultAudioDevice = AudioDevice.EARPIECE
        } else {
            defaultAudioDevice = AudioDevice.SPEAKER_PHONE
        }

        proximitySensor = AppRTCProximitySensor.create(sensorStateListener: onProximitySensorChangedState)
        AppRTCUtils.logDeviceInfo()
    }

    public func start(audioManagerEvents: AudioManagerEvents) throws {
        print("start")
        ThreadUtils.checkIsOnValidThread()
        if amState == AudioManagerState.RUNNING {
            print("AppRTCAudioManager is already active")
            return
        }

        print("AudioManager starts...")
        self.audioManagerEvents = audioManagerEvents
        amState = AudioManagerState.RUNNING

        savedAudioMode = audioManager?.mode ?? AVAudioSession.Mode.default

        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {

            switch output.portType {

            case .builtInSpeaker:
                savedIsSpeakerPhoneOn = true
            default:
                savedIsSpeakerPhoneOn = false
                break
            }
        }
        savedIsMicrophoneMuted = audioManager?.isInputGainSettable ?? false
        hasWiredHeadset = hasWiredHeadsett()

        class MyOnAudioFocusChangeListener: OnAudioFocusChangeListener {
            public func onAudioFocusChange(focusChange: Int) {
                let typeOfChange: String?
                switch (focusChange) {
                case AudioManagerStateAudioFocus.AUDIOFOCUS_GAIN.rawValue:
                    typeOfChange = "AUDIOFOCUS_GAIN"
                    break
                case AudioManagerStateAudioFocus.AUDIOFOCUS_GAIN_TRANSIENT.rawValue:
                    typeOfChange = "AUDIOFOCUS_GAIN_TRANSIENT"
                    break
                case AudioManagerStateAudioFocus.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK.rawValue:
                    typeOfChange = "AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK"
                    break
                case AudioManagerStateAudioFocus.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE.rawValue:
                    typeOfChange = "AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE"
                    break
                case AudioManagerStateAudioFocus.AUDIOFOCUS_LOSS.rawValue:
                    typeOfChange = "AUDIOFOCUS_LOSS"
                    break
                case AudioManagerStateAudioFocus.AUDIOFOCUS_LOSS_TRANSIENT.rawValue:
                    typeOfChange = "AUDIOFOCUS_LOSS_TRANSIENT"
                    break
                case AudioManagerStateAudioFocus.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK.rawValue:
                    typeOfChange = "AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK"
                    break
                default:
                    typeOfChange = "AUDIOFOCUS_INVALID"
                    break
                }
                print("onAudioFocusChange : \(String(describing: typeOfChange))")
            }
        }

        audioFocusChangeListener = MyOnAudioFocusChangeListener()

        let musicPlayer: AVAudioPlayer = AVAudioPlayer()
        musicPlayer.volume = 0
        // stop other audio playing
        try? (AVAudioSession()).setCategory(AVAudioSession.Category.ambient)

        try audioManager?.setMode(AVAudioSession.Mode.voiceChat)
        try audioManager?.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)

        try setMicrophoneMute(on: false)

        userSelectedAudioDevice = AudioDevice.NONE
        selectedAudioDevice = AudioDevice.NONE
        audioDevices.removeAll()

        try bluetoothManager?.start()

        updateAudioDeviceState()

        class MyIntentFilter: IntentFilter {
            var id = "MyIntentFilter"
            var action: [String] = ["ios.intent.action.HEADSET_PLUG"]

            init() {
            }

            func onReceive(intent: Intent) {

            }

            func getAction() -> [String] {
                return action
            }
        }

        wiredHeadsetReceiver?.registerIntentFilter(intentFilter: MyIntentFilter())

        print("AudioManager started")
    }

    public func stop() throws {
        print("stop")
        ThreadUtils.checkIsOnValidThread()
        if amState == AudioManagerState.RUNNING {
            print("Trying to stop AudioManager in incorrect state : \(amState)")
            return
        }
        amState = AudioManagerState.UNINITIALIZED

        wiredHeadsetReceiver?.unregisterReceiver()

        bluetoothManager?.stop()

        // Restore previously stored audio states.
        if let savedIsMicrophoneMuted = savedIsMicrophoneMuted as? Bool, let savedIsSpeakerPhoneOn = savedIsSpeakerPhoneOn as? Bool {
            try setSpeakerphoneOn(on: savedIsSpeakerPhoneOn)
            try setMicrophoneMute(on: savedIsMicrophoneMuted)
        }

        if let audioManager = audioManager {
            try audioManager.setMode(savedAudioMode)
        }

        // Abandon audio focus. Gives the previous focus owner, if any, focus.
        // start other audio playing
        try? (AVAudioSession()).setCategory(AVAudioSession.Category.playback)
        audioFocusChangeListener = nil
        print("Abandoned audio focus for VOICE_CALL streams")

        if var proximitySensor = proximitySensor {
            proximitySensor.stop()
            self.proximitySensor = nil
        }

        audioManagerEvents = nil
        print("AudioManager stopped")
    }

    private func setAudioDeviceInternal(device: AudioDevice) {
        print("setAudioDeviceInternal(device=\(device))")
        AppRTCUtils.assertIsTrue(condition: audioDevices.contains(device))

        switch device {
        case .SPEAKER_PHONE:
            try? setSpeakerphoneOn(on: true)
            break
        case .EARPIECE:
            try? setSpeakerphoneOn(on: false)
            break
        case .WIRED_HEADSET:
            try? setSpeakerphoneOn(on: false)
            break
        case .BLUETOOTH:
            try? setSpeakerphoneOn(on: false)
            break
        default:
            print("Invalid audio device selection")
            break
        }
        selectedAudioDevice = device
    }

    private func setSpeakerphoneOn(on: Bool) throws {
        print("setSpeakerphoneOn(on=\(on))")
        // check if speakerphone is already on
        let currentRoute = AVAudioSession.sharedInstance().currentRoute

        for output in currentRoute.outputs {
            switch output.portType {
            case .builtInSpeaker:
                return
            default:
                break
            }
        }
        try audioManager?.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
    }

    private func setMicrophoneMute(on: Bool) throws {
        print("setMicrophoneMute(on=\(on))")
        if let settable = audioManager?.isInputGainSettable as? Bool, settable {
            try audioManager?.setInputGain(on ? 0 : 1)
        }
    }

    private func hasEarpiece() -> Bool {
        guard let url = URL(string: "tel://") else {
            return false
        }

        let mobileNetworkCode = CTTelephonyNetworkInfo().subscriberCellularProvider?.mobileNetworkCode

        let isInvalidNetworkCode = mobileNetworkCode == nil
                || mobileNetworkCode?.count == 0
                || mobileNetworkCode == "65535"

        return UIApplication.shared.canOpenURL(url)
                && !isInvalidNetworkCode
    }

    private func hasWiredHeadsett() -> Bool {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            switch output.portType {
            case .headphones:
                return true
            default:
                break
            }
        }
        return false
    }

    public func updateAudioDeviceState() {
        ThreadUtils.checkIsOnValidThread()
        if let bluetoothManager = bluetoothManager {
            print("--- updateAudioDeviceState: wired headset=\(hasWiredHeadset), BT state=\(bluetoothManager.getState())")
            print("Device status available=\(audioDevices), selected=\(selectedAudioDevice), user selected=\(userSelectedAudioDevice)")
            if (bluetoothManager.getState() == BluetoothManagerState.HEADSET_AVAILABLE
                    || bluetoothManager.getState() == BluetoothManagerState.HEADSET_UNAVAILABLE
                    || bluetoothManager.getState() == BluetoothManagerState.SCO_DISCONNECTING) {
                bluetoothManager.updateDevice()
            }

            // Update the set of available audio devices.
            var newAudioDevices: Set<AudioDevice> = Set()

            if (bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTED
                    || bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTING
                    || bluetoothManager.getState() == BluetoothManagerState.HEADSET_AVAILABLE) {
                newAudioDevices.insert(AudioDevice.BLUETOOTH)
            }

            if let hasWiredHeadset = hasWiredHeadset as? Bool {
                if (hasWiredHeadset) {
                    // If a wired headset is connected, then it is the only possible option.
                    newAudioDevices.insert(AudioDevice.WIRED_HEADSET)
                } else {
                    // No wired headset, hence the audio-device list can contain speaker
                    // phone (on a tablet), or speaker phone and earpiece (on mobile phone).
                    newAudioDevices.insert(AudioDevice.SPEAKER_PHONE)
                    if (hasEarpiece()) {
                        newAudioDevices.insert(AudioDevice.EARPIECE)
                    }
                }
                // Store state which is set to true if the device list has changed.
                var audioDeviceSetUpdated = !(audioDevices == newAudioDevices)
                // Update the existing audio device set.
                audioDevices = newAudioDevices
                // Correct user selected audio devices if needed.
                if (bluetoothManager.getState() == BluetoothManagerState.HEADSET_UNAVAILABLE
                        && userSelectedAudioDevice == AudioDevice.BLUETOOTH) {
                    // If BT is not available, it can't be the user selection.
                    userSelectedAudioDevice = AudioDevice.NONE
                }
                if (hasWiredHeadset && userSelectedAudioDevice == AudioDevice.SPEAKER_PHONE) {
                    // If user selected speaker phone, but then plugged wired headset then make
                    // wired headset as user selected device.
                    userSelectedAudioDevice = AudioDevice.WIRED_HEADSET
                }
                if (!hasWiredHeadset && userSelectedAudioDevice == AudioDevice.WIRED_HEADSET) {
                    // If user selected wired headset, but then unplugged wired headset then make
                    // speaker phone as user selected device.
                    userSelectedAudioDevice = AudioDevice.SPEAKER_PHONE
                }

                // Need to start Bluetooth if it is available and user either selected it explicitly or
                // user did not select any output device.
                var needBluetoothAudioStart =
                        bluetoothManager.getState() == BluetoothManagerState.HEADSET_AVAILABLE
                                && (userSelectedAudioDevice == AudioDevice.NONE
                                || userSelectedAudioDevice == AudioDevice.BLUETOOTH)

                // Need to stop Bluetooth audio if user selected different device and
                // Bluetooth SCO connection is established or in the process.
                var needBluetoothAudioStop =
                        (bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTED
                                || bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTING)
                                && (userSelectedAudioDevice != AudioDevice.NONE
                                && userSelectedAudioDevice != AudioDevice.BLUETOOTH)

                if (bluetoothManager.getState() == BluetoothManagerState.HEADSET_AVAILABLE
                        || bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTING
                        || bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTED) {
                    print("Need BT audio: start=\(needBluetoothAudioStart), stop=\(needBluetoothAudioStop), BT state=\(bluetoothManager.getState())")
                }

                // Start or stop Bluetooth SCO connection given states set earlier.
                if (needBluetoothAudioStop) {
                    bluetoothManager.stopScoAudio()
                    bluetoothManager.updateDevice()
                }

                if (needBluetoothAudioStart && !needBluetoothAudioStop) {
                    // Attempt to start Bluetooth SCO audio (takes a few second to start).
                    if (!bluetoothManager.startScoAudio()) {
                        // Remove BLUETOOTH from list of available devices since SCO failed.
                        audioDevices.remove(AudioDevice.BLUETOOTH)
                        audioDeviceSetUpdated = true
                    }
                }

                // Update selected audio device.
                var newAudioDevice: AudioDevice?

                if (bluetoothManager.getState() == BluetoothManagerState.SCO_CONNECTED) {
                    // If a Bluetooth is connected, then it should be used as output audio
                    // device. Note that it is not sufficient that a headset is available
                    // an active SCO channel must also be up and running.
                    newAudioDevice = AudioDevice.BLUETOOTH
                } else if (hasWiredHeadset) {
                    // If a wired headset is connected, but Bluetooth is not, then wired headset is used as
                    // audio device.
                    newAudioDevice = AudioDevice.WIRED_HEADSET
                } else {
                    // No wired headset and no Bluetooth, hence the audio-device list can contain speaker
                    // phone (on a tablet), or speaker phone and earpiece (on mobile phone).
                    // |defaultAudioDevice| contains either AudioDevice.SPEAKER_PHONE or AudioDevice.EARPIECE
                    // depending on the user's selection.
                    newAudioDevice = defaultAudioDevice
                }
                // Switch to new device but only if there has been any changes.
                if (newAudioDevice != selectedAudioDevice || audioDeviceSetUpdated) {
                    // Do the required device switch.
                    if let newAudioDevice = newAudioDevice {
                        setAudioDeviceInternal(device: newAudioDevice)
                    }
                    print("New device status: available=\(audioDevices), selected=\(newAudioDevice)")
                    if let audioManagerEvents = audioManagerEvents, let selectedAudioDevice = selectedAudioDevice {
                        // Notify a listening client that audio device has been changed.
                        audioManagerEvents.onAudioDeviceChanged(selectedAudioDevice: selectedAudioDevice, availableAudioDevices: Array(audioDevices))
                    }
                }
            }
        }
        print("--- updateAudioDeviceState done")
    }
}