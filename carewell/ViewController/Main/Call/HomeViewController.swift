//
//  CallListViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit
import WebRTC

protocol MessageDialogCallback {

    func onDismiss()
    func onClicked(id: Int)
}

//extension MessageDialogCallback where Self: Equatable {

//    static func == (lhs: MessageDialogCallback, rhs: MessageDialogCallback) -> Bool {
//        return lhs.id == rhs.id
//    }
//}

enum ButtonType: Int {
    case BTN_LEFT
    case BTN_CENTER
    case BTN_RIGHT

    func ordinal() -> Int {
        return self.rawValue
    }
}

public enum DialogType {
    case INFO_PROGRESS
    case CONFIRM_ONLY
    case CANCEL_ONLY
    case ACCEPT_CANCEL
    case YES_NO_CANCEL
    case REJECT_ACCEPT
}

extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}

@available(iOS 13.0, *)
class HomeViewController: BaseViewController {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

//    @IBOutlet var callTableView: UITableView!

//    @IBOutlet var friendTableView: UITableView!
//
//    @IBOutlet var callTableViewHeight: NSLayoutConstraint!
//    @IBOutlet var friendTableViewHeight: NSLayoutConstraint!

    fileprivate let SHOW_NOTICE_PAGE = "show_notice_page"
    fileprivate let SHOW_SETTING_PAGE = "show_setting_page"
    fileprivate let SHOW_CALL_START_PAGE = "show_call_start_page"
    fileprivate let SHOW_CALL_ADD_PAGE = "show_call_add_page"

    var prevSelected = -1

    private var callModelList: [CallModel] = []
    private var friendModelList: [FriendModel] = []

    // MARK: - override
    public static var isActivated = false
    public static var isActivating = false

    private var mRunningApp: Bool?
    private var eglBaseContext: RTCEAGLVideoView?
    private var userName: String?, mCalleeName: String?, callerName: String?
    private var mSafetyCall = false

    lazy private var surfaceViewRendererLocal: RTCEAGLVideoView? = RTCEAGLVideoView(frame: .zero)
    lazy private var surfaceViewRendererRemote: RTCEAGLVideoView? = RTCEAGLVideoView(frame: .zero)
    lazy private var surfaceViewRendererRemote2: RTCEAGLVideoView? = RTCEAGLVideoView(frame: .zero)

    private var audioManager: AppRTCAudioManager?
    private var mCallingLists: [CallData]?
    private var mGuardianList: [GuardianData]?

    public var mVideoCallService: VideoCallService?

    private var stackView: UIStackView?
    var muteButton: UIButton?
    var cameraButton: UIButton?
    var spkButton: UIButton?
    var hangupButton: UIButton?

    public var doAction: String?
    public var caller: String?
    public var roomId: String?

    @IBOutlet var searchBar: UITextField!
    @IBOutlet var dbListView: UITableView!
    @IBOutlet var dbListViewHeight: NSLayoutConstraint!

    var touched = false

    class VideoCallServiceCallback: IVideoCallServiceCallback {
        var id = "kr.co.carewell.videocall.service.callback2"
        var context: HomeViewController

        public init(context: HomeViewController) {
            self.context = context
        }

        public func onDataChangedInd(what_data: String) {

        }

        public func onStatusInd(status: String, statusCode: Int) {

        }

        public func onMessageReceived(msg_type: String, msg: String, sdata: String, fdata: Float, idata: Int, bdata: Bool, from: String) {
            if msg_type == MsgTypeConfig.TYPE_VIDEO_CALL {
                print("SVC:oMR:TYPE_VIDEO_CALL:\(from), idata:\(idata)")
                context.sendInternalMessage_VideoCall_Status(callData: sdata, status: idata, from: from)
            } else if msg_type == MsgTypeConfig.TYPE_STATUS {
                if msg == "SERVER" {
                    context.sendInternalMessage(what: HomeViewController.Msg_Update_NetworkStatus, arg1: idata)
                }
            }
        }
    }

    lazy var mVideoCallServiceCallback = VideoCallServiceCallback(context: self)

    @available(iOS 13.0, *)
    private func bindVideoCallService() {

        print("HomeViewController: bindVideoCallService()")

        if mVideoCallService != nil, let isBound = mVideoCallService?.isReady as? Bool {
            if isBound {
                if let cancelled = mVideoCallService?.isCancelled as? Bool {
                    if !cancelled {
                        mVideoCallService?.registerCallback(cb: mVideoCallServiceCallback)
                        mGuardianList = mVideoCallService?.getGuardianList()

                        print("onServiceConnected: \(doAction)")
                        if let doAction = doAction as? String, !doAction.isEmpty {
                            if doAction == "CALL" {
                                print("ROOM: \(roomId)")
                                if let roomId, !roomId.isEmpty {
                                    if let roomId = roomId as? UInt64 {
                                        mVideoCallService?.setRoomID(roomId: roomId)
                                    }
                                }
                                if let caller {
                                    sendInternalMessage(what: HomeViewController.Msg_Connect_Calling, data: caller)
                                }
                                roomId = nil
                            } else if doAction == "CALLING" {
                                if let roomId, !roomId.isEmpty {
                                    if let roomId = roomId as? UInt64 {
                                        mVideoCallService?.setRoomID(roomId: roomId)
                                    }
                                }
                                print("onServiceConnected: \(roomId)")
                                if let caller {
                                    sendInternalMessage_VideoCall_Status(callData: "", status: VideoCallStatus.IN_CALL.ordinal(), from: caller)
                                }
                            } else if doAction == "HANGUP" {
                                if let caller {
                                    mVideoCallService?.rejectPeer(calleeName: caller)
                                    mVideoCallService?.hangupPeer(bDestroyRoom: false)
                                }
                            }
                            caller = nil
                        } else {
                            mVideoCallService?.unregisterToken()
                            refreshContactList()
                        }
                        doAction = nil
                        // TODO: Set action
                    }
                }
            }
        }
    }

    private func unbindVideoCallService() {
        if #available(iOS 13.0, *) {
            mVideoCallService?.unregisterCallback(cb: mVideoCallServiceCallback)
            mVideoCallService = nil
        }
    }

    private func resizedImage(_ image: UIImage?) -> UIImage? {
        let imageSize = CGSize(width: 60, height: 60)
        let rect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        image?.draw(in: rect)
        let imageResized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageResized
    }

    private func setRenderer() {
        if #available(iOS 13.0, *), let mVideoCallService {
            // cgsize full screen
            mVideoCallService.initContext()
            // cgrect size: width 120, height 120, with margin top 30, right 30
            var localRect = CGRect(x: UIScreen.main.bounds.size.width - 160, y: 40, width: 120, height: 200)
            DispatchQueue.main.async { [self] in
                surfaceViewRendererLocal = RTCEAGLVideoView(frame: localRect)

                surfaceViewRendererRemote = RTCEAGLVideoView(frame: UIScreen.main.bounds)
                surfaceViewRendererRemote2 = RTCEAGLVideoView(frame: UIScreen.main.bounds)

                mVideoCallService.setViewRenderer(localRenderer: surfaceViewRendererLocal)
                if let surfaceViewRendererLocal, let surfaceViewRendererRemote, let surfaceViewRendererRemote2, let tabBarController = self.tabBarController {
                    tabBarController.view.addSubview(surfaceViewRendererRemote)
                    surfaceViewRendererRemote.isHidden = true
                    surfaceViewRendererRemote.layoutIfNeeded()
                    tabBarController.view.addSubview(surfaceViewRendererRemote2)
                    surfaceViewRendererRemote2.isHidden = true
                    surfaceViewRendererRemote2.layoutIfNeeded()
                    tabBarController.view.addSubview(surfaceViewRendererLocal)

                    // create a button with background image
                    muteButton = UIButton(type: .custom)
                    cameraButton = UIButton(type: .custom)
                    spkButton = UIButton(type: .custom)
                    hangupButton = UIButton(type: .custom)

                    if let resizedMicImage = resizedImage(UIImage(named: "mic_on")) {
                        muteButton?.setImage(resizedMicImage, for: .normal)
                        muteButton?.addTarget(self, action: #selector(onMuteBtnTap), for: .touchUpInside)
                    }

                    if let resizedCameraImage = resizedImage(UIImage(named: "camera_on")) {
                        cameraButton?.setImage(resizedCameraImage, for: .normal)
                        cameraButton?.addTarget(self, action: #selector(onCameraBtnTap), for: .touchUpInside)
                    }

                    if let resizedSpeakerImage = resizedImage(UIImage(named: "icon_spk_off")) {
                        spkButton?.setImage(resizedSpeakerImage, for: .normal)
                        spkButton?.addTarget(self, action: #selector(onSpkBtnTap), for: .touchUpInside)
                    }

                    if let resizedHangupImage = resizedImage(UIImage(named: "call_end")) {
                        hangupButton?.setImage(resizedHangupImage, for: .normal)
                        hangupButton?.addTarget(self, action: #selector(onHangupBtnTap), for: .touchUpInside)
                    }

                    // put them into a stackview
                    stackView = UIStackView(arrangedSubviews: [muteButton!, cameraButton!, spkButton!, hangupButton!])
                    stackView?.axis = .horizontal
                    stackView?.distribution = .fillEqually
                    stackView?.spacing = 10
                    stackView?.translatesAutoresizingMaskIntoConstraints = false
                    tabBarController.view.addSubview(stackView!)
                    stackView?.bottomAnchor.constraint(equalTo: tabBarController.view.bottomAnchor, constant: -20).isActive = true
                    stackView?.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor, constant: 20).isActive = true
                    stackView?.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor, constant: -20).isActive = true
                    stackView?.heightAnchor.constraint(equalToConstant: 60).isActive = true
                }
            }
        }
        audioManager = AppRTCAudioManager.create()

        class MyAudioManagerEvents: AudioManagerEvents {
            private var context: HomeViewController

            public init(context: HomeViewController) {
                self.context = context
            }

            func onAudioDeviceChanged(selectedAudioDevice: AudioDevice, availableAudioDevices: [AudioDevice]) {
                context.onAudioDeviceChanged(selectedAudioDevice: selectedAudioDevice, availableAudioDevices: availableAudioDevices)
            }
        }

        do {
            try audioManager?.start(audioManagerEvents: MyAudioManagerEvents(context: self))
        } catch {
        }
    }

    @objc func onMuteBtnTap(_ sender: UIButton) {
        if let mVideoCallService {
            if let enabled = mVideoCallService.isAudioEnabled() {
                if enabled, let resizedMicImage = resizedImage(UIImage(named: "mic_off")) {
                    muteButton?.setImage(resizedMicImage, for: .normal)
                } else if !enabled, let resizedMicImage = resizedImage(UIImage(named: "mic_on")) {
                    muteButton?.setImage(resizedMicImage, for: .normal)
                }
                mVideoCallService.enableAudio(enable: !enabled)
            }
        }
    }

    @objc func onCameraBtnTap(_ sender: UIButton) {
        if let mVideoCallService {
            if let enabled = mVideoCallService.isVideoEnabled() {
                if enabled, let resizedCameraImage = resizedImage(UIImage(named: "camera_off")) {
                    cameraButton?.setImage(resizedCameraImage, for: .normal)
                    mVideoCallService.enableVideo(enable: false)
                } else if !enabled, let resizedCameraImage = resizedImage(UIImage(named: "camera_on")) {
                    cameraButton?.setImage(resizedCameraImage, for: .normal)
                    mVideoCallService.enableVideo(enable: true)
                }
            }
        }
    }

    @objc func onSpkBtnTap(_ sender: UIButton) {
        if let mVideoCallService {
            let enabled = getSpeakerPhoneMode()
            if enabled, let resizedSpeakerImage = resizedImage(UIImage(named: "icon_spk_off")) {
                spkButton?.setImage(resizedSpeakerImage, for: .normal)
                enableSpeakerPhone(enabled: false)
            } else if !enabled, let resizedSpeakerImage = resizedImage(UIImage(named: "icon_spk_on")) {
                spkButton?.setImage(resizedSpeakerImage, for: .normal)
                enableSpeakerPhone(enabled: true)
            }
        }
    }

    @objc func onHangupBtnTap(_ sender: UIButton) throws {
        if let mVideoCallService {
            mVideoCallService.hangupPeer(bDestroyRoom: false)
        }

        // bottom navigation button not working
        try hangupCall()
        playNoti()
        if !isLockedScreen() {
            refreshCallingList()
        }
    }

    public func onAudioDeviceChanged(selectedAudioDevice: AudioDevice, availableAudioDevices: [AudioDevice]) {
        print("onAudioDeviceChanged: \(selectedAudioDevice)")
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        // showWhenLockedAndTurnScreenOn
        hideKeyboardWhenTappedAround()

        // draw a 1px solid black border around searchbar
        searchBar.borderWitdh = 1.0
        searchBar.borderColor = UIColor(rgb: 0x808080)
        searchBar.cornerRadius = 20.0
        // add a search icon to the right of the searchbar
        let searchIcon = UIImageView(image: UIImage(named: "ic_search_white"))
        searchIcon.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        searchIcon.contentMode = .scaleAspectFit
        searchBar.rightView = searchIcon
        searchBar.rightViewMode = .always

        if mVideoCallService == nil {
            mVideoCallService = VideoCallService()
        }
        HomeViewController.isActivated = true

        mRunningApp = true
        HomeViewController.isActivating = true

        mCallingLists = []

        // TODO: set on click listener to button

        refreshContactList()

        alertSoundInit()
        initMessageHandler()

        sendInternalMessageDelayed(what: HomeViewController.Msg_Hide_Ime, delay: 200)
        sendInternalMessageDelayed(what: HomeViewController.Msg_Init_VideoCall, delay: 300)

        if #available(iOS 13.0, *) {
            bindVideoCallService()
        }

        initView()
    }

    private func requestCall(calleeName: String, bHiddenMe: Bool) {
        UserProperties.setCalleeName(userName: calleeName)
        if #available(iOS 13.0, *), let mVideoCallService {
            mSafetyCall = bHiddenMe
            mCalleeName = calleeName
            mVideoCallService.createRoom()

            let callMessage = HomeViewController.getNickName(phoneNumber: calleeName)

            class MyMessageDialogCallback: MessageDialogCallback {
                private var context: HomeViewController

                public init(context: HomeViewController) {
                    self.context = context
                }

                func onDismiss() {

                }

                func onClicked(id: Int) {

                }
            }

            // show dialog

            showCallerDialog(title: callMessage, message: "Calling...", bAlpha: true, callback: MyMessageDialogCallback(context: self))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("viewWillAppear")

        HomeViewController.isActivating = false
        HomeViewController.isActivated = true

        if #available(iOS 13.0, *), let mVideoCallService {
            print("VideoRoomViewController: viewWillAppear : \(doAction) mVideoCallService: \(mVideoCallService) roomId: \(roomId)")
            if let doAction = doAction, let roomId = roomId, let caller = caller {
                if !doAction.isEmpty {
                    if doAction == "CALL" {
                        if !roomId.isEmpty {
                            if let roomId = roomId as? UInt64 {
                                mVideoCallService.setRoomID(roomId: UInt64(roomId))
                            }
                            print("onServiceConnected: \(roomId)")
                            setRenderer()
                            mVideoCallService.connectToPeer(callerName: caller)
                        }
                    } else if doAction == "CALLING" {
                        sendInternalMessage_VideoCall_Status(callData: "", status: VideoCallStatus.IN_CALL.ordinal(), from: caller)
                    }
                }
            }
        }
    }

    private func isLockedScreen() -> Bool {
        !UIApplication.shared.isProtectedDataAvailable
    }

    private func hangupCall() throws {
        if #available(iOS 13.0, *), let mVideoCallService {
            mSafetyCall = false
            mVideoCallService.setViewRenderer(localRenderer: nil)
            if let audioManager {
                try audioManager.stop()
            }
            audioManager = nil

            if let videoItem = mVideoCallService.getRemoteItem(index: 0) {
                if let surfaceViewRendererRemote, videoItem.videoTrack != nil {
                    videoItem.videoTrack?.remove(surfaceViewRendererRemote)
                }
            }
            if let videoItem = mVideoCallService.getRemoteItem(index: 1) {
                if let surfaceViewRendererRemote2, videoItem.videoTrack != nil {
                    videoItem.videoTrack?.remove(surfaceViewRendererRemote2)
                }
            }

            // remove buttons
            DispatchQueue.main.async { [self] in
                if let surfaceViewRendererLocal {
                    surfaceViewRendererLocal.isHidden = true
                    surfaceViewRendererLocal.removeFromSuperview()
                    surfaceViewRendererLocal.layoutIfNeeded()
                }

                if let surfaceViewRendererRemote {
                    surfaceViewRendererRemote.isHidden = true
                    surfaceViewRendererRemote.removeFromSuperview()
                    surfaceViewRendererRemote.layoutIfNeeded()
                }

                if let surfaceViewRendererRemote2 {
                    surfaceViewRendererRemote2.isHidden = true
                    surfaceViewRendererRemote2.removeFromSuperview()
                    surfaceViewRendererRemote2.layoutIfNeeded()
                }
                hangupButton?.isHidden = true
                hangupButton?.removeFromSuperview()
                hangupButton = nil
                spkButton?.isHidden = true
                spkButton?.removeFromSuperview()
                spkButton = nil
                muteButton?.isHidden = true
                muteButton?.removeFromSuperview()
                muteButton = nil
                cameraButton?.isHidden = true
                cameraButton?.removeFromSuperview()
                cameraButton = nil
                stackView?.isHidden = true
                stackView?.removeFromSuperview()
                stackView = nil
            }

            stopAlert()
            enableSpeakerPhone(enabled: false)
        }

        DispatchQueue.main.async { [self] in
            if !UIApplication.shared.isProtectedDataAvailable {
                finish()
            }
        }
    }

    private func stopAlert() {

    }

    private func getSpeakerPhoneMode() -> Bool {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute

        for output in currentRoute.outputs {
            switch output.portType {
            case .builtInSpeaker:
                return true
            default:
                break
            }
        }
        return false
    }

    private func finish() {
        UIControl().sendAction(#selector(NSXPCConnection.suspend),
                to: UIApplication.shared, for: nil)
    }

    func enableSpeakerPhone(enabled: Bool) {
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.voiceChat)
        if enabled {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } else {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        }
        try? session.setActive(true)
    }

    private func showCustomDialog(type: DialogType, title: String, message: String, bAlpha: Bool, callback: MessageDialogCallback) {
        // show callee dialog
        if let mCalleeDialog = HomeViewController.mCalleeDialog, let dialogType = mCalleeDialog.getType(), dialogType != type {
            mCalleeDialog.removeFromSuperview()
        }

        if HomeViewController.mCalleeDialog == nil {
            let identifier = String(describing: CalleeDialog.self)
            let nibs = Bundle.main.loadNibNamed(identifier, owner: self)
            guard let mCalleeDialog = nibs?.first as? CalleeDialog else {
                return
            }
            HomeViewController.mCalleeDialog = mCalleeDialog
            HomeViewController.mCalleeDialog?.initView(use_multi_callback: true, type: type, title: title, message: message)
            HomeViewController.mCalleeDialog?.addCallback(callback: callback)
        } else if let mCalleeDialog = HomeViewController.mCalleeDialog {
            HomeViewController.mCalleeDialog?.addCallback(callback: callback)
            HomeViewController.mCalleeDialog?.setTitle(title: title)
            HomeViewController.mCalleeDialog?.setMessage(text: message)
        }

        if let mCalleeDialog = HomeViewController.mCalleeDialog {
            if let tabBarController = self.tabBarController {
                tabBarController.view.addSubview(mCalleeDialog)
//            tabBarController.view.bringSubviewToFront(mCalleeDialog)
            }
        }

    }

    private func showCallerDialog(title: String, message: String, bAlpha: Bool, callback: MessageDialogCallback) {
        // implement later
    }

    private func showCalleeDialog(title: String, message: String, bAlpha: Bool, callback: MessageDialogCallback) {
        // implement later
        DispatchQueue.main.async { [self] in
            showCustomDialog(type: DialogType.REJECT_ACCEPT, title: title, message: message, bAlpha: bAlpha, callback: callback)
        }
    }

    public static func getNickName(phoneNumber: String) -> String {
        if UserProperties.getParentNumber() == phoneNumber {
            return UserProperties.getParentName()
        }
        return phoneNumber
    }

    private func alertSoundInit() {
        // TODO: implement later
    }

    private static var Msg_Hide_Ime = 100
    private static var Msg_Video_Call_Status = 130
    private static var Msg_Close_CalleeDialog = 330
    private static var Msg_Update_Controls = 400
    private static var Msg_Show_ViewRender = 500
    private static var Msg_Init_VideoCall = 600
    private static var Msg_Hangup_Called = 700
    private static var Msg_Show_ErrorBox = 800
    private static var Msg_Service_ReConnect = 900
    private static var Msg_Connect_Calling = 1000
    private static var Msg_Update_NetworkStatus = 1100

    static var mCalleeDialog: CalleeDialog? = nil

    // MARK: - IBAction

    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else {
            return
        }

        switch tag {
        case .header_notice_button:
            performSegue(withIdentifier: SHOW_NOTICE_PAGE, sender: nil)

        case .header_setting_button:
            performSegue(withIdentifier: SHOW_SETTING_PAGE, sender: nil)

        case .call_list_add_button:
            performSegue(withIdentifier: SHOW_CALL_ADD_PAGE, sender: nil)

        default:
            break
        }
    }

    var mMessageHandler: NotificationQueue = NotificationQueue.default
    private var mGlobalErrorCode: UInt64 = 1

    private func initMessageHandler() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleMessage), name: Notification.Name.myNotificationKeyMain, object: nil)
    }

    private func setListenerOnConfigurationChanged() {
        NotificationCenter.default.addObserver(self, selector: #selector(onConfigurationChanged), name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc func onConfigurationChanged(notification: Notification) {
        arrangeViewScreen()
    }

    private static var isInRequestCallProcess = false
    private var m_bCalleeMode = false

    @objc func handleMessage(notification: Notification) {
        if let mRunningApp, !mRunningApp {
            return
        }

        if #available(iOS 13.0, *), let msg = notification.object as? [String: Any], let what = msg["what"] as? Int {
            print("what: \(what)")
            if what == HomeViewController.Msg_Service_ReConnect {
                bindVideoCallService()
            } else if what == HomeViewController.Msg_Connect_Calling {
                if let caller = msg["obj"] as? String {
                    if let mVideoCallService, mVideoCallService.isConnectedServer() {
                        setRenderer()
                        mVideoCallService.connectToPeer(callerName: caller)
                    }
                } else if let caller {
                    sendInternalMessageDelayed(what: HomeViewController.Msg_Connect_Calling, data: caller, delay: 500)
                }
            } else if what == HomeViewController.Msg_Update_NetworkStatus {

            } else if what == HomeViewController.Msg_Update_Controls {
                if let mVideoCallService {
                    var enabled = mVideoCallService.isAudioEnabled()
                    // implement later
                }
            } else if what == HomeViewController.Msg_Video_Call_Status {
                if let status = msg["arg1"] as? Int, let data = msg["obj"] as? [String] {
                    let name = data[0] // calldata
                    let from = data[1] // from
                    if status == VideoCallStatus.ROOM_CREATED.ordinal() {
                        if let mCalleeName {
                            setRenderer()
                            mVideoCallService?.callPeer(calleeName: mCalleeName, requestAutoRcv: mSafetyCall)
                        }
                    } else if status == VideoCallStatus.IN_CALL.ordinal() {
                        callerName = data[1]
                        if let mCalleeDialog = HomeViewController.mCalleeDialog {
                            return
                        }

                        if let callerName {
                            let nickname = HomeViewController.getNickName(phoneNumber: callerName)
                            if nickname.isNumber {
                                var callMessage = String(format: "%d", nickname)
                            } else {
                                var callMessage = String(format: "%s", nickname)
                            }
                        }

                        class MyMessageCallback: MessageDialogCallback {
                            var context: HomeViewController

                            init(context: HomeViewController) {
                                self.context = context
                            }

                            func onDismiss() {
                                HomeViewController.isInRequestCallProcess = false
                            }

                            func onClicked(id: Int) {
                                if id == ButtonType.BTN_RIGHT.ordinal() {
                                    context.stopAlert()
                                    context.playNoti()
                                    context.sendInternalMessage(what: HomeViewController.Msg_Close_CalleeDialog)
                                    if let callerName = context.callerName, let mVideoCallService = context.mVideoCallService {
                                        context.setRenderer()
                                        mVideoCallService.connectToPeer(callerName: callerName)
                                    } else {
                                        print("mVideoCallService: \(String(describing: context.mVideoCallService))")
                                        print("수락 실패")
                                    }
                                } else if id == ButtonType.BTN_LEFT.ordinal() {
                                    context.stopAlert()
                                    context.playNoti()
                                    print("Reject Call : \(context.callerName) mVideoCallService: \(context.mVideoCallService)")
                                    if let callerName = context.callerName, let mVideoCallService = context.mVideoCallService {
                                        mVideoCallService.rejectPeer(calleeName: callerName)
                                    }

                                    do {
                                        try context.hangupCall()
                                        context.closeCalleeDialog()
                                        context.refreshCallingList()
                                    } catch {
                                    }
                                    HomeViewController.isInRequestCallProcess = false
                                }
                            }
                        }

                        if let callerName {
                            var callMessage = HomeViewController.getNickName(phoneNumber: callerName)
                            showCalleeDialog(title: callMessage, message: "영상통화 호출입니다.", bAlpha: true, callback: MyMessageCallback(context: self))
                        }

                        playAlert()
                    } else if status == VideoCallStatus.REJECT.ordinal() {
                        if m_bCalleeMode {
                            UserProperties.addNotice()
                        }
                        if let callerName {
                            DBHandler.insertColumn(callerName, callerName, m_bCalleeMode ? CallStatusType.ABSENCE : CallStatusType.REJECT)
                        }
                        sendInternalMessage(what: HomeViewController.Msg_Hangup_Called, arg1: 1)
                        refreshCallingList()
                    } else if status == VideoCallStatus.HANGUP.ordinal() {
                        sendInternalMessage(what: HomeViewController.Msg_Hangup_Called, arg1: 0)
                    } else if status == VideoCallStatus.NOTIFY_ITEM_INSERTED.ordinal() {
                        var peerNum = mVideoCallService?.getPeerCount()
                        print("NOTIFY_ITEM_INSERTED:peerNum:\(peerNum)")
                        arrangeViewScreen()
                        if peerNum == 1 {
                            sendInternalMessage(what: HomeViewController.Msg_Close_CalleeDialog)
                        } else if peerNum == 2 {

                            if mSafetyCall {
                                mVideoCallService?.enableVideo(enable: false)
                                mVideoCallService?.enableAudio(enable: false)
                            }

                            if let surfaceViewRendererRemote {
                                DispatchQueue.main.async {
                                    surfaceViewRendererRemote.isHidden = false
                                    surfaceViewRendererRemote.layoutIfNeeded()
                                }
                            }

                            if let videoItem = mVideoCallService?.getRemoteItem(index: 0) {
                                if let surfaceViewRendererRemote, videoItem.videoTrack != nil {
                                    videoItem.videoTrack?.add(surfaceViewRendererRemote)
                                }
                            }

                            sendInternalMessage(what: HomeViewController.Msg_Close_CalleeDialog)
                            sendInternalMessageDelayed(what: HomeViewController.Msg_Show_ViewRender, delay: 500)
                        } else if peerNum == 3 {

                            if let surfaceViewRendererRemote, let surfaceViewRendererRemote2 {
                                DispatchQueue.main.async {
                                    surfaceViewRendererRemote.isHidden = false
                                    surfaceViewRendererRemote.layoutIfNeeded()
                                    surfaceViewRendererRemote2.isHidden = false
                                    surfaceViewRendererRemote2.layoutIfNeeded()
                                }
                            }

                            if let videoItem = mVideoCallService?.getRemoteItem(index: 0) {
                                if let surfaceViewRendererRemote, videoItem.videoTrack != nil {
                                    videoItem.videoTrack?.add(surfaceViewRendererRemote)
                                }
                            }
                            if let videoItem = mVideoCallService?.getRemoteItem(index: 1) {
                                if let surfaceViewRendererRemote2, videoItem.videoTrack != nil {
                                    videoItem.videoTrack?.add(surfaceViewRendererRemote2)
                                }
                            }

                            sendInternalMessageDelayed(what: HomeViewController.Msg_Show_ViewRender, delay: 500)
                        }
                    } else if status == VideoCallStatus.NOTIFY_ITEM_DELETED.ordinal() {
                        print("NOTIFY_ITEM_DELETED")
                        arrangeViewScreen()
                        if let mVideoCallService {
                            var peerNum = mVideoCallService.getPeerCount()
                            if peerNum == 1 {
                                mVideoCallService.hangupPeer(bDestroyRoom: true)
                                do {
                                    try hangupCall()
                                } catch {
                                }
                                playNoti()
                                DispatchQueue.main.async { [self] in
                                    if !UIApplication.shared.isProtectedDataAvailable {
                                        refreshCallingList()
                                    }
                                }
                            } else if peerNum == 2 {
                                if let videoItem = mVideoCallService.getRemoteItem(index: 0) {
                                    if let surfaceViewRendererRemote, videoItem.videoTrack != nil {
                                        videoItem.videoTrack?.add(surfaceViewRendererRemote)
                                    }
                                }

                                sendInternalMessageDelayed(what: HomeViewController.Msg_Show_ViewRender, delay: 500)
                            } else if peerNum == 3 {
                                if let videoItem = mVideoCallService.getRemoteItem(index: 0) {
                                    if let surfaceViewRendererRemote, videoItem.videoTrack != nil {
                                        videoItem.videoTrack?.add(surfaceViewRendererRemote)
                                    }
                                }

                                if let videoItem = mVideoCallService.getRemoteItem(index: 1) {
                                    if let surfaceViewRendererRemote2, videoItem.videoTrack != nil {
                                        videoItem.videoTrack?.add(surfaceViewRendererRemote2)
                                    }
                                }
                            }
                        }
                    } else if status == VideoCallStatus.COMPLETE_CONNECT.ordinal() {
                        sendInternalMessage(what: HomeViewController.Msg_Close_CalleeDialog)
                        if let mVideoCallService, mSafetyCall {
                            mVideoCallService.enableVideo(enable: false)
                            mVideoCallService.enableAudio(enable: false)
                        }
                    } else if status == VideoCallStatus.ERROR.ordinal() {
                        // parse name to int
                        mGlobalErrorCode = UInt64(Int(name)!)
                        var strMsg = ""
                        if (mGlobalErrorCode == 476) {
                            strMsg = "이미 등록된 사용자 이름입니다. \n다른 이름으로 등록해 주세요."
                        } else if (mGlobalErrorCode == 478), let mCalleeName {
                            strMsg = HomeViewController.getNickName(phoneNumber: mCalleeName) + "님은 현재 온라인상에서 찾을 수 없습니다."
                        } else if (mGlobalErrorCode == 479) {
                            strMsg = "자신에게 전화를 걸 수 없습니다."
                        } else if (mGlobalErrorCode == 900) {
                            strMsg = "상대방이 통화중입니다."
                        } else if (mGlobalErrorCode == 1000) {
                            strMsg = "상대방과 통화 연결이 되지않아 종료되었습니다."
                        } else if (mGlobalErrorCode == 1100) {
                            strMsg = "통화 요청에 대한 상대방의 응답이 없습니다."
                        } else {
                            strMsg = "알 수 없는 오류가 발생하였습니다.(code: \(mGlobalErrorCode))"
                        }

                        // show cupertino alert dialog
                        let alert = UIAlertController(title: "알림", message: strMsg, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [self] action in
                            if mGlobalErrorCode == 476 {
                                finish()
                            }
                        }))
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                        if mGlobalErrorCode == 426 || mGlobalErrorCode == 1000 {
                            if let mVideoCallService {
                                mVideoCallService.hangupPeer(bDestroyRoom: true)
                                playNoti()
                                do {
                                    try hangupCall()
                                } catch {
                                }
                                refreshCallingList()
                            }
                        } else if let mVideoCallService, mVideoCallService.getPeerCount() < 1 {
                            sendInternalMessage(what: HomeViewController.Msg_Hangup_Called, arg1: 0)
                        }
                    }
                }
            } else if what == HomeViewController.Msg_Hide_Ime {
                // dismiss keyboard
                self.view.endEditing(true)
            } else if what == HomeViewController.Msg_Show_ErrorBox {
                sendInternalMessage(what: HomeViewController.Msg_Close_CalleeDialog)
            } else if what == HomeViewController.Msg_Hangup_Called {
                do {
                    try hangupCall()
                } catch {
                }
                sendInternalMessage(what: HomeViewController.Msg_Close_CalleeDialog)
            } else if what == HomeViewController.Msg_Close_CalleeDialog {
                closeCalleeDialog()
            } else if what == HomeViewController.Msg_Show_ViewRender {
                if !mSafetyCall {

                }

                if let mVideoCallService, let peerCount = mVideoCallService.getPeerCount() as? Int, peerCount >= 3 {

                } else {

                }

                enableSpeakerPhone(enabled: true)
                sendInternalMessage(what: HomeViewController.Msg_Update_Controls)
            }
        }
    }

    private func closeCalleeDialog() {
        if HomeViewController.mCalleeDialog != nil {
            DispatchQueue.main.async {
                HomeViewController.mCalleeDialog?.release()
                HomeViewController.mCalleeDialog?.removeCallback()
                HomeViewController.mCalleeDialog?.removeFromSuperview()
                HomeViewController.mCalleeDialog = nil
//                if let tabBarController = self.tabBarController {
//                    tabBarController.view.addSubview(mCalleeDialog)
//                    tabBarController.view.bringSubviewToFront(mCalleeDialog)
//                }
            }
        }
    }

    private func playNoti() {

    }

    private func playAlert() {

    }

    public func refreshCallingList() {
        mCallingLists?.removeAll()
    }

    public func refreshContactList() {
        if mGuardianList == nil {
            return
        }

        // TODO: implement later
    }

    private func getScreenOrientation() -> UIDeviceOrientation {
        return UIDevice.current.orientation
    }

    private func arrangeViewScreen() {
        // implement later
    }


    private func sendInternalMessageCallback(what: String, delayMs: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delayMs) / 1000.0)) { [self] in
            mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": what]), postingStyle: .now)
        }
    }

    private func sendInternalMessage(what: Int) {
        mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": what]), postingStyle: .now)
    }

    private func sendInternalMessage(what: Int, arg1: Int) {
        mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": what, "arg1": arg1]), postingStyle: .now)
    }

    private func sendInternalMessage(what: Int, data: String) {
        mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": what, "obj": data]), postingStyle: .now)
    }

    private func sendInternalMessageDelayed(what: Int, delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0)) { [self] in
            mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": what]), postingStyle: .now)
        }
    }

    private func sendInternalMessageDelayed(what: Int, data: String, delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0)) { [self] in
            mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": what, "obj": data]), postingStyle: .now)
        }
    }

    private func sendInternalMessage_VideoCall_Status(callData: String, status: Int, from: String) {
        mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyMain, object: ["what": HomeViewController.Msg_Video_Call_Status, "obj": [callData, from], "arg1": status]), postingStyle: .now)
    }

    // MARK: - function

    func initView() {
        dbListView.delegate = self
        dbListView.dataSource = self
        dbListView.alwaysBounceVertical = false

        let nibName = UINib(nibName: "CallListCell", bundle: nil)
        dbListView.register(nibName, forCellReuseIdentifier: "callCell")

        mVideoCallService?.getGuardianList()?.forEach { element in
            if let name = element.getSilverName() as? String, let phone = element.getNumber() as? String {
                callModelList.append(CallModel(name, phone))
            }
        }

        dbListView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // TODO: implement later
//        HomeViewController.isActivated = false
    }
}

// MARK: - Extension UITableViewDelegate, UITableViewDataSource

@available(iOS 13.0, *)
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if touched {
            if prevSelected == indexPath.row {
                return 145
            } else {
                return 90
            }
        }
        DispatchQueue.main.async { [self] in
            let cell = tableView.cellForRow(at: indexPath) as! CallListCell
            cell.icons.isHidden = true
            cell.iconTop.constant = 0
            cell.iconBottom.constant = 0
            cell.setSelected(false, animated: false)
        }
        return 90
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        callModelList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "callCell", for: indexPath) as! CallListCell
        cell.model = callModelList[indexPath.row]
        cell.delegate = self
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = bgColorView

        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        touched = true
        if prevSelected == indexPath.row {
            self.dbListViewHeight.constant = CGFloat(90 * callModelList.count)
            prevSelected = -1
        } else {
            self.dbListViewHeight.constant = CGFloat(145 + 90 * (callModelList.count - 1))
            prevSelected = indexPath.row
        }
        tableView.reloadData()
        DispatchQueue.main.async { [self] in
            for i in 0..<callModelList.count {
                let curCell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! CallListCell
                curCell.icons.isHidden = true
                curCell.iconTop.constant = 0
                curCell.iconBottom.constant = 0
//                cell.setSelected(false, animated: false)
            }
            if prevSelected != -1 {
                let cell = tableView.cellForRow(at: indexPath) as! CallListCell
                cell.icons.isHidden = false
                cell.iconTop.constant = 5
                cell.iconBottom.constant = 5
                cell.setSelected(true, animated: false)
            }
            tableView.sizeToFit()
        }
    }
}

// MARK: - Extension

//
@available(iOS 13.0, *)
extension HomeViewController: CallListCellDelegate {
    func onTapCall() {
        requestCall(calleeName: "백도연", bHiddenMe: false)
    }

    func onTapSafetyCall() {
        requestCall(calleeName: "백도연", bHiddenMe: false)
    }
}
