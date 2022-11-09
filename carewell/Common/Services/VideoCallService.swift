//
// Created by DOYEON BAEK on 2022/10/20.
//

import Foundation
import WebRTC
import CameraManager
import CallKit
import Reachability
import BackgroundTasks
import CoreData

enum MessageIds: Int {
    case Msg_Video_ConnectServer = 10
    case Msg_Init_VideoCall = 100
    case Msg_Reject_Calling = 200
    case Msg_RejectCall_inService = 300
    case Msg_Network_Avialable = 800
    case Msg_Network_Unavialable = 810
    case Msg_Network_Lost = 820
    case Msg_Check_JoinPeer = 1100
    case Msg_Keep_Alive = 1300
    case Msg_Checking_KeepAlive = 1400
    case Msg_Wait_CallStandBy = 1500
}

extension Int {
    func toMessageIds() -> MessageIds {
        switch self {
        case 10:
            return .Msg_Video_ConnectServer
        case 100:
            return .Msg_Init_VideoCall
        case 200:
            return .Msg_Reject_Calling
        case 300:
            return .Msg_RejectCall_inService
        case 800:
            return .Msg_Network_Avialable
        case 810:
            return .Msg_Network_Unavialable
        case 820:
            return .Msg_Network_Lost
        case 1100:
            return .Msg_Check_JoinPeer
        case 1300:
            return .Msg_Keep_Alive
        case 1400:
            return .Msg_Checking_KeepAlive
        case 1500:
            return .Msg_Wait_CallStandBy
        default:
            return .Msg_Video_ConnectServer
        }
    }
}

class HashableMessage {
    var id: MessageIds
    var what: Int
    var caller: String?

    init(what: Int, caller: String? = nil) {
        self.what = what
        self.id = what.toMessageIds()
        self.caller = caller
    }

    func isEqual(message: HashableMessage) -> Bool {
        return self.id == message.id && self.what == message.what && self.caller == message.caller
    }
}

extension HashableMessage: Hashable {
    static func ==(lhs: HashableMessage, rhs: HashableMessage) -> Bool {
        return lhs.id == rhs.id && lhs.what == rhs.what && lhs.caller == rhs.caller
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(what)
        hasher.combine(caller)
    }
}


protocol CreateOfferCallback {
    func onCreateOfferSuccess(offer: RTCSessionDescription)
    func onCreateFailed(error: String)
}

protocol CreateAnswerCallback {
    func onCreateAnswerSuccess(answer: RTCSessionDescription)
    func onCreateAnswerFailed(error: String)
}

protocol CreatePeerConnectionCallback {
    func onIceGatheringComplete()
    func onIceCandidate(candidate: RTCIceCandidate)
    func onIceCandidatesRemoved(candidates: [RTCIceCandidate])
    func onAddStream(stream: RTCMediaStream)
    func onRemoveStream(stream: RTCMediaStream)
}

protocol Callback {
    func callStateChanged(_ state: Int)
}

extension Notification.Name {
    static let myNotificationKey = Notification.Name.init("kr.co.carewell.messagehandler")
    static let myNotificationKeySplash = Notification.Name.init("kr.co.carewell.messagehandler.splash")
    static let myNotificationKeyCert = Notification.Name.init("kr.co.carewell.messagehandler.cert")
    static let myNotificationKeyProximity = Notification.Name.init("kr.co.carewell.messagehandler.proximity")
    static let myNotificationKeyBluetooth = Notification.Name.init("kr.co.carewell.messagehandler.bluetooth")
    static let myNotificationKeyMain = Notification.Name.init("kr.co.carewell.messagehandler.main")
}

@available(iOS 13.0, *)
class MyCreateOfferCallback: CreateOfferCallback {

    private var context: VideoCallService?

    init(context: VideoCallService) {
        self.context = context
    }

    func onCreateOfferSuccess(offer: RTCSessionDescription) {
        print("onSuccess")
        if let videoRoomHandlerId = context?.videoRoomHandlerId {
            context?.mJoinedRoom = true
            context?.janusClient?.publish(handleId: videoRoomHandlerId, sdp: offer)
        }
    }

    func onCreateFailed(error: String) {
        print("CreateOfferCallback onCreateFailed")
    }
}

@available(iOS 13.0, *)
final class VideoCallService: Operation, IntentFilter {
    var id = "VideoCallService"
    var action: [String] = ["kr.co.carewell.videocallservice"]

    func getAction() -> [String] {
        return action
    }

    static var shared: VideoCallService = VideoCallService()

    var context: NSManagedObjectContext?
    var predicate: NSPredicate?

    static var KEEPALIVE_TIME: Int = 60 * 5 * 1000

    static var JANUS_URL: String = "ws://rtc.carewellplus.co.kr:8188/"
    var janusClient: JanusClient?
    var room: Room = Room(id: 1234)
    var mRoomId: UInt64?
    var network_status = 0, mReconnectCount = 0
    var mbUserRegistered = false
    var mJoinedRoom = false
    var mbReconnectServer: Bool?
    static var mUserName: String = UserProperties.getUserName()
    var videoRoomHandlerId: Decimal?
    var mCallerName: String?, mCalleeName: String?
    var callerSDP: String? = nil
    var surfaceViewRendererLocal: RTCEAGLVideoView?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    private var videoItemList: [VideoItem] = []
    private var hasUserInfo = false
    public var mGuardiansList: [GuardianData]?
    public var delayedWorkItemList: [HashableMessage: DispatchWorkItem]? = [:]
    var callback: CreatePeerConnectionCallback?
    var callback2: CreatePeerConnectionCallback?

    // implement later

    // due to the difference between android and ios, the service api call can be called directly from the activity
    // remote api call
    private var callbacks: [IVideoCallServiceCallback] = []

    func getService() -> VideoCallService {
        return self
    }

    public func registerCallback(cb: IVideoCallServiceCallback) {
        callbacks.append(cb)
    }

    public func unregisterCallback(cb: IVideoCallServiceCallback) {
        callbacks.removeAll(where: { callback in
            callback.id == cb.id
        })
    }

    public func setViewRenderer(localRenderer: RTCEAGLVideoView?) {
        if let localRenderer {
            self.surfaceViewRendererLocal = localRenderer
        }
    }

    public func getGuardianList() -> [GuardianData]? {
        if let mGuardiansList {
            return mGuardiansList
        }
        return nil
    }

    public func hasUserInfoo() -> Bool {
        return self.hasUserInfo
    }

    public func setUserInfoFlag(bHave: Bool) {
        self.hasUserInfo = bHave
    }

    public func isRegistered() -> Bool {
        return mbUserRegistered
    }

    public func registerUser(userName: String) {
        VideoCallService.mUserName = userName
        if let janusClient = janusClient, let videoRoomHandlerId, let mMacAddr {
            janusClient.registPeer(handleId: videoRoomHandlerId, name: VideoCallService.mUserName, macAddr: mMacAddr)
        }
    }

    public func initContext() {
        initialize(bInitCall: true)
    }

    public func requestRoomList() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
            janusClient.requestRoomList(handleId: videoRoomHandlerId)
        }
    }

    public func testToken(token: String) {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
            janusClient.testToken(handleId: videoRoomHandlerId, token: token)
        }
    }

    public func registerToken() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId, let mFcmToken = mFcmToken {
            janusClient.registerToken(handleId: videoRoomHandlerId, token: mFcmToken)
        }
    }

    public func unregisterToken() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId, let mFcmToken = mFcmToken {
            janusClient.unregisterToken(handleId: videoRoomHandlerId, token: mFcmToken)
        }
    }

    public func createRoom() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
            janusClient.createRoom(handleId: videoRoomHandlerId, roomNumber: -1)
        }
    }

    public func destroyRoom() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId, let mRoomId = mRoomId {
            janusClient.destroyRoom(handleId: videoRoomHandlerId, roomId: mRoomId)
        }
    }

    public func joinRoom() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId, let mRoomId = mRoomId {
            janusClient.joinRoom(handleId: videoRoomHandlerId, roomId: mRoomId, displayName: VideoCallService.mUserName)
        }
    }

    public func setRoomID(roomId: UInt64) {
        if roomId != 0, var mRoomId {
            mRoomId = roomId
            room = Room(id: mRoomId)
        }
    }

    public func connectToPeer(callerName: String) {
        if let mMessageHandler {
//            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
            delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
        }

        if videoRoomHandlerId == nil {
            print("data lost!!!!!")
            videoRoomHandlerId = DataLoseControlHandler.videoRoomHandlerId
        }

        print("peerConnection: \(peerConnection)") // nil
        print("audioTrack: \(audioTrack)") // nil

        if let videoRoomHandlerId, let peerConnection, let janusClient, let audioTrack, let videoTrack, let mRoomId {
            peerConnection.add(audioTrack, streamIds: [])
            peerConnection.add(videoTrack, streamIds: [])
            janusClient.acceptCallByFCM(handleId: videoRoomHandlerId, name: callerName)
            janusClient.joinRoom(handleId: videoRoomHandlerId, roomId: mRoomId, displayName: VideoCallService.mUserName)
        }
    }

    public func connectRenderer(remoteRenderer: RTCEAGLVideoView, calleeName: String) {
        videoItemList.forEach({ videoItem in
            if calleeName == videoItem.display {
                if videoItem.videoTrack != nil {
                    videoItem.videoTrack?.add(remoteRenderer)
                }
            }
        })
    }

    public func getVideoItem(calleeName: String) -> VideoItem? {
        var ret: VideoItem?
        videoItemList.forEach({ videoItem in
            if calleeName == videoItem.display {
                ret = videoItem
                return
            }
        })
        return ret
    }

    public func getVideoItem(index: Int) -> VideoItem? {
        if index < videoItemList.count {
            return videoItemList[index]
        }
        return nil
    }

    public func getRemoteItem(index: Int) -> VideoItem? {
        var item = 0
        for videoItem in videoItemList {
            if !(VideoCallService.mUserName == videoItem.display) {
                if item == index {
                    return videoItem
                }
                item += 1
            }
        }
        return nil
    }

    public func getPeerCount() -> Int {
        if videoItemList != nil {
            return videoItemList.count
        }
        return 0
    }

    public func callPeer(calleeName: String, requestAutoRcv: Bool) {
        mCalleeName = calleeName
        if let janusClient, let videoRoomHandlerId, let mRoomId, let mCalleeName {
            janusClient.callPeer(handleId: videoRoomHandlerId, roomNo: mRoomId, name: mCalleeName, bAutoReceive: requestAutoRcv)
            sendInternalMessageDelayed(what: VideoCallService.Msg_Wait_CallStandBy, delay: 5000)
        }
    }

    public func rejectPeer(calleeName: String) {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
            print("rejectPeer:janusClient:\(janusClient):videoRoomHandlerId:\(videoRoomHandlerId)")
            janusClient.rejectCallByFCM(handleId: videoRoomHandlerId, name: calleeName)
        }
        if let mMessageHandler {
//            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
            delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()

        }
    }

    public func hangupPeer(bDestroyRoom: Bool) {
        print("hangupPeer()")
        if let mMessageHandler {
//            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
            delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
        }
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
            janusClient.hangupPeer(handleId: videoRoomHandlerId)
            if bDestroyRoom, let mRoomId = mRoomId {
                janusClient.destroyRoom(handleId: videoRoomHandlerId, roomId: mRoomId)
            }
            deinitVideoCall()
        }
        sendInternalMessageDelayed(what: VideoCallService.Msg_Video_ConnectServer, delay: 500)
    }

    public func isAudioEnabled() -> Bool? {
        if let isEnabled = audioTrack?.isEnabled {
            return isEnabled
        }
        return nil
    }

    public func enableVideo(enable: Bool) {
        if let videoTrack = videoTrack {
            videoTrack.isEnabled = enable
        }
    }

    public func isVideoEnabled() -> Bool? {
        if let isEnabled = videoTrack?.isEnabled {
            return isEnabled
        }
        return nil
    }

    public func enableAudio(enable: Bool) -> Bool? {
        if let audioTrack = audioTrack {
            audioTrack.isEnabled = enable
        }
        return nil
    }

    public func isConnectedServer() -> Bool {
        return videoRoomHandlerId != nil ? true : false
    }

    public func isAvailableNetwork() -> Bool {
        return network_status == 1 ? true : false
    }

    // end remote api call

    override init() {
        super.init()
        print("Started service!!!!!!!!!!")

        initMessageHandler()

        addIntentFilter()
        CustomNotification.createNotificationChannel()

        mbReconnectServer = true

        mGuardiansList = []

//        FirebaseMessaging


        registNetworkCallback()
        DBHandler.initialize()

        let callCntr = CXCallObserver()
        callCntr.setDelegate(self, queue: nil)

        sendInternalMessageDelayed(what: VideoCallService.Msg_Video_ConnectServer, delay: 1)
    }


    private func isOnPhoneCall() -> Bool {
        let callCntr = CXCallObserver()

        if let calls = callCntr.calls as? [CXCall] {
            for call in calls {
                if call.hasConnected && !call.hasEnded {
                    return true
                }
            }
        }
        print("no calls")
        return false
    }

    private var mConnectivityManager: Reachability?

//    public static from(binder: Binder) -> VideoCallService {
//        return VideoCallService()
//    }

    private var sentKeepAlive = false
//    private var mMessageHandler: Handler? = nil

//    private var mConnectivityManager: ConnectivityManager

    var pendingAction: String?
    var caller: String?
    var mRoom: String?

    var mFcmToken: String?
    private var audioTrack: RTCAudioTrack?
    private var audioSource: RTCAudioSource?
    private var videoTrack: RTCVideoTrack?, remoteVideoTrack: RTCVideoTrack?
    private var videoSource: RTCVideoSource?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var isFrontCamera: Bool = true

    override func start() {
        print("onStartCommand: mUserName = \(VideoCallService.mUserName)")
        if pendingAction != nil {
            if pendingAction == "HANGUP" {
                if let caller = caller {
                    print("PedingAction: HANGUP, caller: \(caller), janusClient: \(janusClient) : \(videoRoomHandlerId)")
                    CustomNotification.cancel(10)
                    if let mMessageHandler {
//                        mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
                        delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
                    }
                    if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
                        sendInternalMessage(what: VideoCallService.Msg_RejectCall_inService, caller: caller)
                    } else {
                        sendInternalMessageDelayed(what: VideoCallService.Msg_RejectCall_inService, delay: 500)
                    }
                    VideoCallService.mUserName = UserProperties.getUserNumber()
                }
            } else if pendingAction == "CALLING" {
                if let caller = caller, let mRoom = mRoom {
                    CustomNotification.setNotification("CALL", caller, mRoom)
                }
            } else {
                if !VideoCallService.mUserName.isEmpty {
                    UserProperties.setUserNumber(userNumber: VideoCallService.mUserName)
                }
            }
        } else {
            VideoCallService.mUserName = UserProperties.getUserNumber()
            print("onStartCommand : userName = \(VideoCallService.mUserName)")
            initialize(bInitCall: true)
        }

//        return START_STICKY
    }

    override func waitUntilFinished() {
        close()
        super.waitUntilFinished()

        print("onTaskRemoved called")
    }

    private func close() {
        if let mMessageHandler {
//            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Init_VideoCall]), coalesceMask: 0)
            delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Init_VideoCall)]?.cancel()
//            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Video_ConnectServer]), coalesceMask: 0)
            delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Video_ConnectServer)]?.cancel()
        }
        mMessageHandler = nil

        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId, let mFcmToken = mFcmToken {
            janusClient.registerToken(handleId: videoRoomHandlerId, token: mFcmToken)
        }

        deinitVideoCall()

    }

    override func cancel() {
        close()
        DBHandler.deinitialize()
        removeIntentFilter()
        unregistNetworkCallback()
    }

    // override func onBind(intent: Intent): IBinder? {

    private static var AUDIO_ECHO_CANCELLATION_CONSTRAINT: String = "googEchoCancellation"
    private static var AUDIO_AUTO_GAIN_CONTROL_CONSTRAINT: String = "googAutoGainControl"
    private static var AUDIO_HIGH_PASS_FILTER_CONSTRAINT: String = "googHighpassFilter"
    private static var AUDIO_NOISE_SUPPRESSION_CONSTRAINT: String = "googNoiseSuppression"

    private func initialize(bInitCall: Bool) {

        peerConnectionFactory = createPeerConnectionFactory()
        var audioConstraints = RTCMediaConstraints(mandatoryConstraints: [
            VideoCallService.AUDIO_ECHO_CANCELLATION_CONSTRAINT: "true",
            VideoCallService.AUDIO_AUTO_GAIN_CONTROL_CONSTRAINT: "true",
            VideoCallService.AUDIO_HIGH_PASS_FILTER_CONSTRAINT: "true",
            VideoCallService.AUDIO_NOISE_SUPPRESSION_CONSTRAINT: "true"
        ], optionalConstraints: nil)

        audioSource = peerConnectionFactory?.audioSource(with: audioConstraints)
        audioTrack = peerConnectionFactory?.audioTrack(with: audioSource!, trackId: "101")

        videoSource = peerConnectionFactory?.videoSource()
        if videoSource != nil {
            videoCapturer = createVideoCapturer(isFront: isFrontCamera, delegate: videoSource!)
        }

        guard videoCapturer != nil else {
            return
        }

//        videoCapturer = RTCCameraVideoCapturer(delegate: self)

        videoTrack = peerConnectionFactory?.videoTrack(with: videoSource!, trackId: "102")

        if bInitCall {
            initVideoCall()
        }
    }

    private func hangupCall() {
        if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
            deinitVideoCall()

            sendInternalMessageDelayed(what: VideoCallService.Msg_Video_ConnectServer, delay: 500)
        }
    }

    private func addIntentFilter() {
        IntentManager.shared.registerIntentFilter(intentFilter: self)
    }

    private func removeIntentFilter() {
        IntentManager.shared.unregisterIntentFilter(intentFilter: self)
    }

    func onReceive(intent: Intent) {
        var currentState: UIDevice.BatteryState = .unknown
        let action = intent.action
        if action == "ROOMLIST" {
            if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
                janusClient.requestRoomList(handleId: videoRoomHandlerId)
            }
        } else if action == "ACTION_MONITOR_SERVICE.CHECKING_SERVICE" {
            sendInternalMessageDelayed(what: VideoCallService.Msg_Checking_KeepAlive, delay: 500)
        } else if currentState == .charging {
            sendInternalMessageDelayed(what: VideoCallService.Msg_Checking_KeepAlive, delay: 500)
        } else if currentState == .unplugged {
            sendInternalMessageDelayed(what: VideoCallService.Msg_Checking_KeepAlive, delay: 500)
        }
    }

    private func initVideoCall() {
        if let mMessageHandler {
//            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Video_ConnectServer]), coalesceMask: 0)
            delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Video_ConnectServer)]?.cancel()
        }
        if peerConnectionFactory != nil {
            initialize(bInitCall: false)
        }
        print("initVideoCall()")

        mbReconnectServer = true
        if janusClient == nil {
            janusCallback = MyJanusCallback(service: self)
            janusClient = JanusClient(janusUrl: VideoCallService.JANUS_URL, macAddress: mMacAddr)
            if let janusClient {
                janusClient.setJanusCallback(janusCallback: janusCallback)
                janusClient.connect()
            }
        }

        if peerConnection == nil {
            class MyPeerConnectionCallback: CreatePeerConnectionCallback {
                let context: VideoCallService

                public init(context: VideoCallService) {
                    self.context = context
                }

                func onIceGatheringComplete() {
                    if let handleId = context.videoRoomHandlerId {
                        context.janusClient?.trickleCandidateComplete(handleId: handleId)
                    }

                }

                func onIceCandidate(candidate: RTCIceCandidate) {
                    if let handleId = context.videoRoomHandlerId {
                        context.janusClient?.trickleCandidate(handleId: handleId, iceCandidate: candidate)
                    }
                }

                func onIceCandidatesRemoved(candidates: [RTCIceCandidate]) {
                    context.peerConnection?.remove(candidates)
                }

                func onAddStream(stream: RTCMediaStream) {
                    print("onAddStream : \(stream.videoTracks.count)")
                    if stream.videoTracks.count > 0 {
                        context.remoteVideoTrack = stream.videoTracks[0]

                        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                            var bestFormat: AVCaptureDevice.Format? = nil
                            var bestFrameRateRange: AVFrameRateRange? = nil
                            for format in frontCamera.formats {
                                for range in format.videoSupportedFrameRateRanges {
                                    if bestFormat == nil || bestFrameRateRange == nil || range.maxFrameRate > bestFrameRateRange!.maxFrameRate {
                                        bestFormat = format
                                        bestFrameRateRange = range
                                    }
                                }
                            }
                            if let bestFormat, let bestFrameRateRange, context.videoCapturer != nil {
                                context.videoCapturer!.startCapture(with: frontCamera, format: bestFormat, fps: Int(bestFrameRateRange.maxFrameRate))
                            }
                            if context.videoTrack != nil, context.surfaceViewRendererLocal != nil {
                                context.videoTrack!.add(context.surfaceViewRendererLocal!)
                            }

                            if let callerName = context.mCallerName {
                                context.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.COMPLETE_CONNECT.ordinal(), bdata: false, from: callerName)
                            }
                        }
                    }
                }

                func onRemoveStream(stream: RTCMediaStream) {

                }
            }

            peerConnection = createPeerConnection(MyPeerConnectionCallback(context: self), true)
        }
    }

    private func deinitVideoCall() {
        if let _ = janusClient {
            print("deinitVideoCall : \(janusClient)")

            mbReconnectServer = false
            mJoinedRoom = false
            mbUserRegistered = false
            unregisterRestartAlive()
            if let mMessageHandler {
//                mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Checking_KeepAlive]), coalesceMask: 0)
                delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Checking_KeepAlive)]?.cancel()
            }

            if let videoCapturer = videoCapturer {
                videoCapturer.stopCapture()
            }

            if let janusClient = janusClient {
                janusClient.disconnect()
            }
            janusClient = nil
            audioTrack = nil
            audioSource = nil
            videoCapturer = nil

            for videoItem in videoItemList {
                if videoItem.peerConnection != nil {
                    videoItem.peerConnection?.close()
                    videoItem.peerConnection = nil
                }

                if videoItem.videoTrack != nil {
                    videoItem.videoTrack = nil
                }

                if videoItem.surfaceViewRenderer != nil {
                    videoItem.surfaceViewRenderer = nil
                }
            }

            videoItemList.removeAll()

            peerConnection = nil

            peerConnectionFactory = nil

            mRoomId = 0
            videoRoomHandlerId = nil
            print("deinitVideoCall!!!!!!!!!!")
        }
    }

    private func broadcastMessageReceived(whatTypeMsg: String, whatMsg: String?, sdata: String?, fdata: Float, idata: Int, bdata: Bool, from: String) {
//        var n = callbacks.beginBroadcast()
        var n = callbacks.count
        while n > 0 {
            n -= 1
            var callback: IVideoCallServiceCallback = callbacks[n]
            callback.onMessageReceived(msg_type: whatTypeMsg, msg: whatMsg ?? "", sdata: sdata ?? "", fdata: fdata, idata: idata, bdata: bdata, from: from)
        }
//        callbacks.finishBroadcast()
    }

    let center = NotificationCenter.default
    var mMessageHandler: NotificationQueue? = NotificationQueue.default

    private static var Msg_Video_ConnectServer = 10
    private static var Msg_Init_VideoCall = 100
    private static var Msg_Reject_Calling = 200
    private static var Msg_RejectCall_inService = 300

    private static var Msg_Network_Avialable = 800
    private static var Msg_Network_Unavialable = 810
    private static var Msg_Network_Lost = 820
    private static var Msg_Check_JoinPeer = 1100
    private static var Msg_Keep_Alive = 1300
    private static var Msg_Checking_KeepAlive = 1400
    private static var Msg_Wait_CallStandBy = 1500


    private func initMessageHandler() {

        center.addObserver(self, selector: #selector(handleMessage(_:)), name: Notification.Name.myNotificationKey, object: nil)

//        queue.enqueue(Notification(name: Notification.Name.NSExtensionHostDidBecomeActive), postingStyle: .asap)
    }

    @objc func handleMessage(_ notification: Notification) {
        if let obj = notification.object as? [String: Any], let what = obj["what"] as? Int {
            if what == VideoCallService.Msg_Video_ConnectServer {
                if let janusClient = janusClient {
                    print("Msg_Video_ConnectServer:network_status: \(network_status) janusClient: \(janusClient)")
                }
//                if true {
                if UserProperties.isCertified() {
                    if var mMacAddr, mMacAddr.isEmpty {
                        mMacAddr = UserProperties.getAppUUID()
                    }

                    if network_status == 1, janusClient == nil {
                        janusClient = JanusClient(janusUrl: VideoCallService.JANUS_URL, macAddress: mMacAddr)
                        janusClient?.setJanusCallback(janusCallback: janusCallback)
                        janusClient?.connect()
                    }
                } else {
                    sendInternalMessageDelayed(what: VideoCallService.Msg_Video_ConnectServer, delay: 3000)
                }
            } else if what == VideoCallService.Msg_Wait_CallStandBy {
                var errorCode: String = String(format: "%d", 1100)
                if let mCallerName = mCallerName {
                    broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: errorCode, fdata: 0, idata: VideoCallStatus.ERROR.ordinal(), bdata: false, from: mCallerName)
                }
            } else if what == VideoCallService.Msg_Checking_KeepAlive {
                unregisterRestartAlive()
                print("Msg: Msg_Checking_KeepAlive : \(janusClient)")
                sentKeepAlive = true
                if janusClient != nil {
                    janusClient?.sendKeepAlive()
                    if let mMessageHandler {
//                        mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Checking_KeepAlive]), coalesceMask: 0)
                        delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Checking_KeepAlive)]?.cancel()
                    }
                    var bm: BatteryManager = BatteryManager()
                    if bm.isCharging() {
                        sendInternalMessageDelayed(what: VideoCallService.Msg_Keep_Alive, delay: VideoCallService.KEEPALIVE_TIME)
                    } else {
                        unregisterRestartAlive()
                    }
                }
            } else if what == VideoCallService.Msg_Keep_Alive {
                print("Msg : Msg_Keep_Alive : \(janusClient)")
                sentKeepAlive = true
                if janusClient != nil {
                    janusClient?.sendKeepAlive()
//                mMessageHandler?.removeMessages(what: VideoCallService.Msg_Keep_Alive)
                    if let mMessageHandler {
//                        mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Keep_Alive]), coalesceMask: 0)
                        delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Keep_Alive)]?.cancel()
                    }

                    var bm: BatteryManager = BatteryManager()
                    if !bm.isCharging() {
                        registerRestartAlive()
                        return
                    }
                    unregisterRestartAlive()
                }
            } else if what == VideoCallService.Msg_Init_VideoCall {
                initVideoCall()
            } else if what == VideoCallService.Msg_Check_JoinPeer {
                print("Error: No Joined Peer!!!!")
                if HomeViewController.isActivated {
                    var errorCode: String = String(format: "%d", 1000)
                    if let mCallerName = mCallerName {
                        broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: errorCode, fdata: 0, idata: VideoCallStatus.ERROR.ordinal(), bdata: false, from: mCallerName)
                    }
                } else {
                    hangupPeer(bDestroyRoom: true)
                }
            } else if what == VideoCallService.Msg_Reject_Calling {
                if let mCallerName = mCallerName {
                    if HomeViewController.isActivated {
                        broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.REJECT.ordinal(), bdata: false, from: mCallerName)
                    }
                    if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
                        janusClient.rejectCall(handleId: videoRoomHandlerId, name: mCallerName)
                    }
                    hangupCall()

                    CustomNotification.cancelAll()
                    CustomNotification.NotifyMissedCall(mCallerName)
                }
            } else if what == VideoCallService.Msg_RejectCall_inService {
                if let userInfo = notification.userInfo as? [String: Any], let caller = userInfo["caller"] as? String {
                    print("Msg_RejectCall_inService:janusClient:\(janusClient):videoRoomHandlerId:\(videoRoomHandlerId):caller:\(caller)")
                    if let janusClient = janusClient, let videoRoomHandlerId = videoRoomHandlerId {
                        janusClient.rejectCallByFCM(handleId: videoRoomHandlerId, name: caller)
                        hangupCall()
                        if let mCalleeName = mCalleeName {
                            DBHandler.insertColumn(caller, caller, CallStatusType.REJECT)
                        } else {
                            DBHandler.insertColumn(caller, caller, CallStatusType.ABSENCE)
                            UserProperties.addNotice()
                        }
                    } else {
                        sendInternalMessageDelayed(what: VideoCallService.Msg_RejectCall_inService, caller: caller, delay: 500)
                    }
                }
            } else if what == VideoCallService.Msg_Network_Avialable {
                var activeNetwork = mConnectivityManager?.connection
                if network_status == 0 || !mPrevNetwork_WifiMode {
                    network_status = 1
                    mPrevNetwork_WifiMode = activeNetwork != Reachability.Connection.none

                    sendInternalMessageDelayed(what: VideoCallService.Msg_Video_ConnectServer, delay: 100)
                    broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_STATUS, whatMsg: "NETWORK", sdata: nil, fdata: 0, idata: 1, bdata: false, from: "")
                }
            } else if what == VideoCallService.Msg_Network_Unavialable || what == VideoCallService.Msg_Network_Lost {
                network_status = 0
                deinitVideoCall()
                broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_STATUS, whatMsg: "NETWORK", sdata: nil, fdata: 0, idata: 0, bdata: false, from: "")
            }
        }
    }

    private var janusCallback: JanusCallback?

    class MyJanusCallback: JanusCallback {
        var service: VideoCallService

        public init(service: VideoCallService) {
            self.service = service
        }

        func onCreateSession(_ sessionId: Decimal) {
            service.janusClient?.attachPlugin(pluginName: "janus.plugin.videoroom")
            var bm: BatteryManager = BatteryManager()
            if bm.isCharging() {
                print("battery manager not working....")
                service.sendInternalMessageDelayed(what: VideoCallService.Msg_Keep_Alive, delay: KEEPALIVE_TIME)
                return
            }
            service.unregisterRestartAlive()
            service.registerRestartAlive()
        }

        func onAttached(_ handleId: Decimal) {
            print("onAttached : mUserName: \(mUserName): \(UserProperties.getUserNumber()) : \(handleId)")
            service.videoRoomHandlerId = handleId
            DataLoseControlHandler.videoRoomHandlerId = handleId
            if mUserName == nil || mUserName.isEmpty {
                // TODO: error 처리!!!
                // TODO: user cert 과정 처리
                // TODO: 방 생성 및 입장, 영상통화 처리
                mUserName = Global.shared.getPhoneNumber()
//                mUserName = UUID().uuidString
//                mUserName = UserProperties.getUserNumber()
            }
            if let macAddr = service.mMacAddr {
                service.janusClient?.registPeer(handleId: handleId, name: mUserName, macAddr: macAddr)
            }
            service.mReconnectCount = 0
            service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_STATUS, whatMsg: "SERVER", sdata: nil, fdata: 0, idata: 1, bdata: false, from: "")
        }

        func onSubscribeAttached(_ subscribeHandleId: Decimal, _ feedId: Decimal) {
            if let publisher = service.room.findPublisherById(id: feedId) {
                publisher.setHandleId(handleId: subscribeHandleId)
                service.janusClient?.subscribe(subscriptionHandleId: subscribeHandleId, roomId: service.room.getId(), feedId: feedId)
            }
        }

        func onDetached(_ handleId: Decimal, reason: String?) {
            service.unregisterRestartAlive()
            if let mMessageHandler = service.mMessageHandler {
//                mMessageHandler.removeMessages(what: VideoCallService.Msg_Keep_Alive)
//                mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Keep_Alive]), coalesceMask: 0)
                service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Keep_Alive)]?.cancel()
                service.sentKeepAlive = false
            }
            service.videoRoomHandlerId = nil
            if let _ = service.mbReconnectServer {
                service.janusClient = nil
                service.sendInternalMessageDelayed(what: VideoCallService.Msg_Video_ConnectServer, delay: 3000 + 5000 * service.mReconnectCount)
                service.mReconnectCount += 1
                if service.mReconnectCount > 5 {
                    service.mReconnectCount = 5
                }
                service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_STATUS, whatMsg: "SERVER", sdata: nil, fdata: 0, idata: 0, bdata: false, from: "")
            }
            print("onDetached: \(service.mbReconnectServer) :\(service.mReconnectCount) : \(service.videoRoomHandlerId)")
        }

        func onHangup(_ handleId: Decimal) {
            print("onHangup: \(handleId)")
        }

        func onMessage(_ sender: Decimal, _ handleId: Decimal, _ msg: Any, _ jsep: Any) {
            // if msg has videoroom
            if let msg = msg as? [String: Any] {
                if let type = msg["videoroom"] as? String {
                    if type == "created" {
                        if let roomId = msg["room"] as? NSNumber {
                            service.mRoomId = roomId.uint64Value
                            service.room = Room(id: service.mRoomId!)
                            service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.ROOM_CREATED.ordinal(), bdata: false, from: mUserName)
                        }
                    } else if type == "joined" {
                        service.createOffer(callback: MyCreateOfferCallback(context: service))
                        service.sendInternalMessageDelayed(what: VideoCallService.Msg_Check_JoinPeer, delay: 10000)
                        if let publishers = msg["publishers"] as? [Dictionary<String, AnyObject>] {
                            service.handleNewPublishers(publishers: publishers)
                        }
                    } else if type == "event" {
                        if let configured = msg["configured"] as? String, configured == "ok" {
                            if let peerConnection = service.peerConnection, let jsep = jsep as? [String: Any] {
                                guard let sdp: String = jsep["sdp"] as? String else {
                                    return
                                }
                                peerConnection.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: sdp), completionHandler: { [self] (error) in
                                    if let error = error {
                                        print("setRemoteDescription onCreateFailure \(error)")
                                    } else {
                                        print("setRemoteDescription onCreateSuccess")

                                        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                                            var bestFormat: AVCaptureDevice.Format? = nil
                                            var bestFrameRateRange: AVFrameRateRange? = nil
                                            for format in frontCamera.formats {
                                                for range in format.videoSupportedFrameRateRanges {
                                                    if bestFormat == nil || bestFrameRateRange == nil || range.maxFrameRate > bestFrameRateRange!.maxFrameRate {
                                                        bestFormat = format
                                                        bestFrameRateRange = range
                                                    }
                                                }
                                            }
                                            if let bestFormat, let bestFrameRateRange, service.videoCapturer != nil {
                                                print("startcapture!!!!")
                                                service.videoCapturer!.startCapture(with: frontCamera, format: bestFormat, fps: Int(bestFrameRateRange.maxFrameRate))
                                            }

                                            var videoItem: VideoItem = service.addNewVideoItem(nil, mUserName)
                                            videoItem.peerConnection = service.peerConnection
                                            videoItem.videoTrack = service.videoTrack

                                            service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.NOTIFY_ITEM_INSERTED.ordinal(), bdata: false, from: mUserName)
                                            if service.videoTrack != nil, service.surfaceViewRendererLocal != nil {
                                                service.videoTrack!.add(service.surfaceViewRendererLocal!)
                                            }
                                        }
                                    }
                                })
                            }
                        } else if let unpublished = msg["unpublished"] as? NSNumber {
                            var unPublishedUserId: UInt64 = unpublished.uint64Value
                        } else if let leavingUserId = msg["leaving"] as? NSNumber {

                            print("leaving: \(leavingUserId)")
                            service.room.removePublisherById(leavingUserId.decimalValue)
                            service.videoItemList.enumerated().forEach({ (index, videoItem) in
                                print("user id: \(videoItem.userId)")
                                if leavingUserId.decimalValue == videoItem.userId {
                                    print("remove video item: \(index)")

                                    if videoItem.peerConnection != nil {
                                        videoItem.peerConnection?.close()
                                    }
                                    if videoItem.videoTrack != nil {
                                        videoItem.videoTrack = nil
                                    }
                                    if videoItem.surfaceViewRenderer != nil {
                                        DispatchQueue.main.async {
                                            videoItem.surfaceViewRenderer?.removeFromSuperview()
                                            videoItem.surfaceViewRenderer?.layoutIfNeeded()
                                        }
                                    }

                                    service.videoItemList.removeAll(where: { $0.userId == leavingUserId.decimalValue })
                                    // get current index in videoItemList
                                    service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.NOTIFY_ITEM_DELETED.ordinal(), bdata: false, from: String(format: "%d", index))
                                }
                            })
                        } else if let publishers = msg["publishers"] as? [Dictionary<String, AnyObject>] {
                            if service.mMessageHandler != nil {
                                // TODO
                                print("mMessageHandler: \(service.mMessageHandler)")
//                                service.mMessageHandler?.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Check_JoinPeer]), coalesceMask: 0)
                                service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Check_JoinPeer)]?.cancel()
                                print(service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Check_JoinPeer)])
                            }
                            service.handleNewPublishers(publishers: publishers)
                        } else if let started = msg["started"] as? String, started == "ok" {
                            print("subscription started ok")
                        } else if let registered = msg["registered"] as? String, registered == "ok" {
                            service.mbUserRegistered = true
                            service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.REGISTERED.ordinal(), bdata: false, from: mUserName)
                        }

                        if let results = msg["result"] as? [String: Any] {
                            guard let event = results["event"] as? String else {
                                return
                            }
                            if event == "registered" {
                                // Peer 등록
                                service.mbUserRegistered = true
                                service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.REGISTERED.ordinal(), bdata: false, from: mUserName)
                            } else if event == "calling" {
                                // 전화거는중
                            } else if event == "incomingcall" {
                                service.mCalleeName = nil
                                service.mCallerName = results["username"] as? String
                                if service.isOnPhoneCall() {
                                    if let janusClient = service.janusClient, let videoRoomHandlerId = service.videoRoomHandlerId, let mCallerName = service.mCallerName {
                                        janusClient.rejectByBusy(handleId: videoRoomHandlerId, name: mCallerName)
                                    }
                                    if let mMessageHandler = service.mMessageHandler {
//                                        mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
                                        service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
                                    }

                                    return
                                } else if service.mLineBusy {
                                    if let janusClient = service.janusClient, let videoRoomHandlerId = service.videoRoomHandlerId, let mCallerName = service.mCallerName {
                                        janusClient.rejectByBusy(handleId: videoRoomHandlerId, name: mCallerName)
                                    }
                                    if let mMessageHandler = service.mMessageHandler {
//                                        mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
                                        service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
                                    }

                                    return
                                }

                                if let janusClient = service.janusClient, let videoRoomHandlerId = service.videoRoomHandlerId, let mCallerName = service.mCallerName {
                                    janusClient.replyCallStandBy(handleId: videoRoomHandlerId, name: mCallerName)
                                }

                                if let mRoomId = results["room"] as? UInt64 {
                                    service.mRoomId = mRoomId
                                    service.room = Room(id: mRoomId)

                                    if let jsep = jsep as? [String: Any], let sdp = jsep["sdp"] as? String {
                                        service.callerSDP = sdp
                                    }

                                    if let mCallerName = service.mCallerName {
                                        print("전화옴")
                                        service.NotifyIncomingCall(name: mUserName, from: mCallerName)
                                    }
                                }
                            } else if event == "standby" {
//                                service.mMessageHandler?.removeMessages(what: Msg_Wait_CallStandBy)
                                if let mMessageHandler = service.mMessageHandler {
//                                    mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Wait_CallStandBy]), coalesceMask: 0)
                                    service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Wait_CallStandBy)]?.cancel()
                                }
                            } else if event == "accepted" {
//                                service.mMessageHandler?.removeMessages(what: Msg_Wait_CallStandBy)
                                if let mMessageHandler = service.mMessageHandler {
//                                    mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Wait_CallStandBy]), coalesceMask: 0)
                                    service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Wait_CallStandBy)]?.cancel()
                                }

                                if !service.mJoinedRoom {
                                    if let audioTrack = service.audioTrack, let videoTrack = service.videoTrack, let peerConnection = service.peerConnection {
                                        peerConnection.add(audioTrack, streamIds: [])
                                        peerConnection.add(videoTrack, streamIds: [])
                                    }

                                    if let janusClient = service.janusClient, let videoRoomHandlerId = service.videoRoomHandlerId, let mRoomId = service.mRoomId {
                                        janusClient.joinRoom(handleId: videoRoomHandlerId, roomId: mRoomId, displayName: mUserName)
                                    }
                                }
                            } else if event == "rejected" {
                                if let requestUser = results["username"] as? String {
                                    if (service.mCalleeName != nil && service.mCalleeName == requestUser) || (service.mCallerName != nil && service.mCallerName == requestUser) {
                                        CustomNotification.cancelAll()
                                        if service.mCalleeName == nil {
                                            if let mMessageHandler = service.mMessageHandler {
//                                                mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
                                                service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
                                            }
                                            if service.mCallerName == nil, let username = results["username"] as? String {
                                                service.mCallerName = username
                                            }

                                            if let mCallerName = service.mCallerName {
                                                CustomNotification.NotifyMissedCall(mCallerName)
                                            }
                                        } else {
                                            if let janusClient = service.janusClient, service.videoItemList.count <= 0, let videoRoomHandlerId = service.videoRoomHandlerId, let mRoomId = service.mRoomId {
                                                janusClient.destroyRoom(handleId: videoRoomHandlerId, roomId: mRoomId)
                                            }
                                        }

                                        if HomeViewController.isActivated {
                                            service.hangupCall()
                                            if let mCallerName = service.mCallerName {
                                                service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.REJECT.ordinal(), bdata: false, from: mCallerName)
                                            }
                                        } else {
                                            if service.mCalleeName == nil && service.mCallerName != nil {
//                                                        DbHandler.insertColumn(mCallerName, mCallerName, CallStatusType.ABSENCE)
                                                service.hangupCall()
                                            }
                                        }
                                    }
                                }
                            } else if event == "hangup" {
                                if let mMessageHandler = service.mMessageHandler {
//                                    mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Wait_CallStandBy]), coalesceMask: 0)
                                    service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Wait_CallStandBy)]?.cancel()
//                                    mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
                                    service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()

                                    if let reason = results["reason"] as? String {
                                        print("hangup EVENT: \(reason)")
                                        if let mCalleeName = service.mCalleeName, service.videoItemList.count <= 1 {
                                            if let janusClient = service.janusClient, let videoRoomHandlerId = service.videoRoomHandlerId, let mRoomId = service.mRoomId {
                                                janusClient.destroyRoom(handleId: videoRoomHandlerId, roomId: mRoomId)
                                            }
                                        }
                                        service.hangupCall()
                                        if let mCallerName = service.mCallerName {
                                            if reason == "User busy" {
                                                var errorCode = String(format: "%d", 900)
                                                service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: errorCode, fdata: 0, idata: VideoCallStatus.ERROR.ordinal(), bdata: false, from: mCallerName)
                                            } else {
                                                service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: VideoCallStatus.HANGUP.ordinal(), bdata: false, from: mCallerName)
                                            }
                                        }
                                    }
                                }
                            }
                        } else if let error_code = msg["error_code"] as? Int {
//                            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Wait_CallStandBy]), coalesceMask: 0)
                            service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Wait_CallStandBy)]?.cancel()
//                            mMessageHandler.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Reject_Calling]), coalesceMask: 0)
                            service.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Reject_Calling)]?.cancel()
                            var errorCode = String(format: "%d", error_code)
                            service.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: errorCode, fdata: 0, idata: VideoCallStatus.ERROR.ordinal(), bdata: false, from: service.mCallerName ?? "")
                        } else if let hangup = msg["hangup"] as? [String: Any] {

                        }
                    } else if type == "attached" {
                        if let jsep = jsep as? [String: Any], let sdp = jsep["sdp"] as? String, let feedIdRaw = msg["id"] as? NSNumber, let display = msg["display"] as? String {
                            print("event: attached!!!!")

                            var publisher = service.room.findPublisherById(id: feedIdRaw.decimalValue)

                            // Add user to interface
                            var videoItem = service.addNewVideoItem(feedIdRaw.decimalValue, display)

                            class MyCreatePeerConnectionCallback: CreatePeerConnectionCallback {

                                var context: VideoCallService
                                var videoItem: VideoItem
                                var feedId: Decimal
                                var display: String
                                var sender: Decimal

                                public init(_ context: VideoCallService, videoItem: VideoItem, feedId: Decimal, display: String, sender: Decimal) {
                                    self.context = context
                                    self.videoItem = videoItem
                                    self.feedId = feedId
                                    self.display = display
                                    self.sender = sender
                                }

                                func onIceGatheringComplete() {
                                    context.janusClient?.trickleCandidateComplete(handleId: sender)
                                }

                                func onIceCandidate(candidate: RTCIceCandidate) {
                                    print("onIceCandidate: \(candidate)")
                                    if let janusClient = context.janusClient {
                                        janusClient.trickleCandidate(handleId: sender, iceCandidate: candidate)
                                    }
                                }

                                func onIceCandidatesRemoved(candidates: [RTCIceCandidate]) {

                                }

                                func onAddStream(stream: RTCMediaStream) {
                                    print("onAddStream: \(stream)")
                                    if stream.videoTracks.count > 0 {
                                        videoItem.videoTrack = stream.videoTracks[0]
                                        print("videoTrack : \(videoItem.videoTrack)")
                                        context.broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: "\(feedId)", fdata: 0, idata: VideoCallStatus.NOTIFY_ITEM_INSERTED.ordinal(), bdata: false, from: display)
                                        if context.mMessageHandler != nil {
                                            // not working
//                                            context.mMessageHandler?.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Check_JoinPeer]), coalesceMask: 0)
                                            context.delayedWorkItemList?[HashableMessage(what: VideoCallService.Msg_Check_JoinPeer)]?.cancel()
                                        }
                                    }
                                }

                                func onRemoveStream(stream: RTCMediaStream) {
                                }
                            }

                            var peerConnection = service.createPeerConnection(MyCreatePeerConnectionCallback(service, videoItem: videoItem, feedId: feedIdRaw.decimalValue, display: display, sender: sender), false)
                            videoItem.peerConnection = peerConnection
                            if let peerConnection {
                                peerConnection.setRemoteDescription(RTCSessionDescription(type: .offer, sdp: sdp), completionHandler: { (error) in
                                    if let error = error {
                                        print("setRemoteDescription error : \(error)")
                                        return
                                    }
                                    print("setRemoteDescription success")

                                    class MyCreateAnswerCallback: CreateAnswerCallback {
                                        var context: VideoCallService
                                        var publisher: Publisher
                                        var room: Room

                                        public init(_ context: VideoCallService, publisher: Publisher, room: Room) {
                                            self.context = context
                                            self.publisher = publisher
                                            self.room = room
                                        }

                                        func onCreateAnswerSuccess(answer: RTCSessionDescription) {
                                            if let handleId = publisher.getHandleId() {
                                                context.janusClient?.subscriptionStart(subscriptionHandleId: handleId, roomId: room.getId(), sdp: answer)
                                            }
                                        }

                                        func onCreateAnswerFailed(error: String) {
                                            print("onCreateAnswerFailed : \(error)")
                                        }
                                    }

                                    if let publisher {
                                        print("peerConnection : \(peerConnection)")
                                        print("publisher : \(publisher)")
                                        print("creating answer!!!")
                                        self.service.createAnswer(peerConnection, callback: MyCreateAnswerCallback(self.service, publisher: publisher, room: self.service.room))
                                    } else {
                                        print("creating answer failed.")
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }

        func onIceCandidate(_ handleId: Decimal, _ candidate: Any) {
            // code
        }

        func onDestroySession(_ sessionId: Decimal) {
            // code
        }

        func onError(_ error: String) {
            // code
        }
    }

    private func NotifyIncomingCall(name: String, from: String) {
        print("NotifyIncomingCall : VideoRoomAciivity.isActivated:\(HomeViewController.isActivated)")
        mCallerName = from
        if HomeViewController.isActivated {
            print("mUserName:\(VideoCallService.mUserName) mCallerName:\(mCallerName)")
            if let mCallerName {
                SendVideoCaLL_Message(msg: VideoCallService.mUserName, from: mCallerName, status: VideoCallStatus.IN_CALL.ordinal())
            }
        } else if let mRoomId = mRoomId {
            CustomNotification.setNotification(name, from, String(format: "%d", mRoomId))
        }
    }

    private func SendVideoCaLL_Message(msg: String, from: String, status: Int) {
        print("SendVideoCaLL_Message \(status)")
        if !HomeViewController.isActivated {
            print("+Wait to isActivating:from:\(from)")
            var nLoop: Int = 0
            while nLoop < 10, !HomeViewController.isActivated {
                sleep(100)
                nLoop += 1
            }
            print("-Wait to isActivating:\(HomeViewController.isActivated)")
        }

        if HomeViewController.isActivated {
            broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: status, bdata: false, from: from)
        } else {
            print("+call VideoRoomActivity")
//            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let newViewController = storyBoard.instantiateViewController(withIdentifier: "newViewController") as! NewViewController
//            self.present(newViewController, animated: true, completion: nil)
            print("+Wait to isActivating:from:\(from)")
            var nLoop: Int = 0
            while nLoop < 10, !HomeViewController.isActivated {
                sleep(100)
                nLoop += 1
            }
            print("-Wait to isActivating:\(HomeViewController.isActivated)")
            broadcastMessageReceived(whatTypeMsg: MsgTypeConfig.TYPE_VIDEO_CALL, whatMsg: nil, sdata: nil, fdata: 0, idata: status, bdata: false, from: from)
        }
    }

    private func createPeerConnectionFactory() -> RTCPeerConnectionFactory {
        RTCInitializeSSL()

        let encoderFactory: RTCDefaultVideoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory: RTCDefaultVideoDecoderFactory = RTCDefaultVideoDecoderFactory()
        let factory: RTCPeerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        for codecInfo in RTCDefaultVideoEncoderFactory.supportedCodecs() {
            if codecInfo.name.elementsEqual("H264") {
                encoderFactory.preferredCodec = codecInfo
                break
            }
        }
        return factory
    }

    private func createPeerConnection(_ callback: CreatePeerConnectionCallback, _ v2: Bool) -> RTCPeerConnection? {
        print("createPeerConnection:\(peerConnectionFactory)")
        guard let peerConnectionFactory = peerConnectionFactory else {
            return nil
        }
        var iceServerList = [RTCIceServer]()
        iceServerList.append(RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]))
        iceServerList.append(RTCIceServer(urlStrings: ["turn:turn.markx.co.kr:3478"], username: "markx", credential: "markt2021"))
        let rtcConfig = RTCConfiguration()
        rtcConfig.iceServers = iceServerList
        rtcConfig.iceTransportPolicy = .all
        rtcConfig.bundlePolicy = .balanced
        rtcConfig.rtcpMuxPolicy = .require
        rtcConfig.tcpCandidatePolicy = .enabled
        rtcConfig.candidateNetworkPolicy = .all
        rtcConfig.continualGatheringPolicy = .gatherOnce

        if !v2 {
            self.callback = callback
        } else {
            self.callback2 = callback
        }

//        let delegate = MyPeerConnectionCallback(callback: callback)
        // delegate는 무조건 self로 해야함. 아니면 작동안됨
        let peerConnection: RTCPeerConnection = peerConnectionFactory.peerConnection(with: rtcConfig, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: self)
        print("peerConnection:\(peerConnection)")

        return peerConnection
    }

    private func createOffer(callback: CreateOfferCallback) {
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        if peerConnection != nil {
            peerConnection?.offer(for: mediaConstraints, completionHandler: { [self] (sdp, error) in
                if let error = error {
                    print("createOffer error: \(error)")
                    callback.onCreateFailed(error: "\(error)")
                    return
                }
                if let sdp = sdp {
                    peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                        if let error = error {
                            print("setLocalDescription error: \(error)")
                            callback.onCreateFailed(error: "\(error)")
                            return
                        } else if callback != nil {
                            print("setLocalDescription onCreateSuccess")
                            callback.onCreateOfferSuccess(offer: sdp)
                        } else {
                            print("setLocalDescription failed")
                        }
                    })
                }
            })
        }
    }

    private func createAnswer(_ peerConnection: RTCPeerConnection, callback: CreateAnswerCallback) {
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        if peerConnection != nil {
            peerConnection.answer(for: mediaConstraints, completionHandler: { [self] (sdp, error) in

                if let error = error {
                    print("onCreateAnswerFailed...")
                    callback.onCreateAnswerFailed(error: "\(error)")
                    return
                }
                if let sdp = sdp {
                    // onSetSuccess
                    peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                        if let error = error {
                            print("setLocalDescription error: \(error)")
                            callback.onCreateAnswerFailed(error: "\(error)")
                            return
                        } else if callback != nil {
                            print("setLocalDescription onCreateAnswerSuccess")
                            callback.onCreateAnswerSuccess(answer: sdp)
                        } else {
                            print("setLocalDescription failed")
                        }
                    })
                }
            })
        }
    }

    public class VideoItem {
        var peerConnection: RTCPeerConnection?
        public var userId: Decimal?
        public var display: String?
        public var videoTrack: RTCVideoTrack?
        public var surfaceViewRenderer: RTCEAGLVideoView?

        public init() {
        }
    }

    private func addNewVideoItem(_ userId: Decimal?, _ display: String) -> VideoItem {
        let videoItem: VideoItem = VideoItem()
        videoItem.userId = userId
        videoItem.display = display
        videoItemList.append(videoItem)
        return videoItem
    }

    private func sendInternalMessage(what: Int, caller: String) {
        if let mMessageHandler {
//            var msg: Message = Message()
//            msg.what = what
//            msg.obj = caller
//            mMessageHandler.sendMessage(message: msg)
            mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKey, object: ["what": what], userInfo: ["caller": caller]), postingStyle: .now)
        }
    }

    private func sendInternalMessageDelayed(what: Int, delay: Int) {
        if let mMessageHandler {
            let workItem = DispatchWorkItem {
                mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKey, object: ["what": what]), postingStyle: .now)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0), execute: workItem)
            delayedWorkItemList?[HashableMessage(what: what)] = workItem
        }
    }

    private func sendInternalMessageDelayed(what: Int, caller: String, delay: Int) {
        if let mMessageHandler {
//            var msg: Message = Message()
//            msg.what = what
//            msg.obj = caller
//            mMessageHandler.sendMessageDelayed(message: msg, delayMillis: delay)
            // run after some delay
            let workItem = DispatchWorkItem {
                mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKey, object: ["what": what], userInfo: ["caller": caller]), postingStyle: .now)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0), execute: workItem)
            delayedWorkItemList?[HashableMessage(what: what, caller: caller)] = workItem
        }
    }

    private func handleNewPublishers(publishers: [Dictionary<String, AnyObject>]) {
        for publishObj in publishers {
            if let feed = publishObj["id"] as? NSNumber {
                guard var feedId = Decimal(string: feed.stringValue) else {
                    continue
                }
                var display: String = publishObj["display"] as! String
                janusClient?.subscribeAttach(feedId: feedId)
                room.addPublisher(publisher: Publisher(id: feedId, display: display))
            }
        }
    }


    private func createVideoCapturer(isFront: Bool, delegate: RTCVideoSource) -> RTCCameraVideoCapturer? {
        if isFront {
            AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            return RTCCameraVideoCapturer.captureDevices().first { (device) -> Bool in
                        return device.position == .front
                    }
                    .map { (device) -> RTCCameraVideoCapturer in
                        return RTCCameraVideoCapturer(delegate: delegate)
                    }
        } else {
            AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
            return RTCCameraVideoCapturer.captureDevices().first { (device) -> Bool in
                        return device.position == .back
                    }
                    .map { (device) -> RTCCameraVideoCapturer in
                        return RTCCameraVideoCapturer(delegate: delegate)
                    }
        }
    }

    public func registNetworkCallback() {
        mConnectivityManager = try! Reachability()
        mMacAddr = UserProperties.getAppUUID()

        // get active networks
        var activeNetwork = mConnectivityManager?.connection
        if let mMessageHandler, activeNetwork == Reachability.Connection.none {
//            mMessageHandler.sendEmptyMessageDelayed(what: VideoCallService.Msg_Network_Lost, delayMillis: 100)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Network_Lost]), postingStyle: .now)
            }
            network_status = 0
        } else {
            network_status = 1
            mPrevNetwork_WifiMode = activeNetwork == Reachability.Connection.wifi
        }
        print("registNetworkCallback: \(network_status)")

        // register netowrk callback to connectivity manager
        mConnectivityManager?.whenReachable = { [self] reachability in
            if reachability.connection == Reachability.Connection.wifi {
                self.mPrevNetwork_WifiMode = true
            } else {
                self.mPrevNetwork_WifiMode = false
            }
            if let mMessageHandler {
                if activeNetwork != Reachability.Connection.none {
                    //                mMessageHandler.sendEmptyMessageDelayed(what: VideoCallService.Msg_Network_Avialable, delayMillis: 100)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Network_Avialable]), postingStyle: .now)
                    }
                } else {
//                mMessageHandler?.sendEmptyMessageDelayed(what: VideoCallService.Msg_Network_Unavialable, delayMillis: 100)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKey, object: ["what": VideoCallService.Msg_Network_Unavialable]), postingStyle: .now)
                    }
                }

            }
        }
    }

    private func unregistNetworkCallback() {
        mConnectivityManager?.stopNotifier()
        mConnectivityManager = nil
    }

    public static func getNickName(phoneNumber: String) -> String {
        if phoneNumber == UserProperties.getParentNumber() {
            return UserProperties.getParentName()
        }
        return phoneNumber
    }

    private var mMacAddr: String?
    private var mPrevNetwork_WifiMode = false
    private var mLineBusy = false

    private func registerRestartAlive() {
        // register alarm
        var date = Date()
        // add KEEPALIVE_TIME(ms) and 3000ms to the date
        date.addTimeInterval(TimeInterval(VideoCallService.KEEPALIVE_TIME / 1000 + 3))
        let notiCenter = UNUserNotificationCenter.current()

        notiCenter.getNotificationSettings(completionHandler: { settings in
            if settings.authorizationStatus == UNAuthorizationStatus.authorized {
                let nContents = UNMutableNotificationContent()
                nContents.badge = 1
                nContents.title = "알림"
                nContents.subtitle = "서브타이틀"
                nContents.body = "부재중 영상통화가 있습니다."
                nContents.sound = UNNotificationSound.default
                nContents.userInfo = ["name": "Infomark"]

                let trigger = UNCalendarNotificationTrigger(dateMatching: date.toDateComponent()!, repeats: false)
                let request = UNNotificationRequest(identifier: Consts().ACTION_RESTART_MONITOR_ALIVE, content: nContents, trigger: trigger)

                notiCenter.add(request) { error in
                    if let error = error {
                        print(error)
                    }
                }

                var currTimeMs = Date().timeIntervalSince1970 * 1000
                print("RESTART CHECKING ALIVE RUN...................:\(currTimeMs) WakeOn:\(Int(currTimeMs) + VideoCallService.KEEPALIVE_TIME + 3000)")
            }
        })
    }

    private func unregisterRestartAlive() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Consts().ACTION_RESTART_MONITOR_ALIVE])
    }

}

@available(iOS 13.0, *)
extension VideoCallService: CXCallObserverDelegate {
    override var description: String {
        return "VideoCallService"
    }

    override func isEqual(_ object: Any?) -> Bool {
        // code
        false
    }

    override var hash: Int {
        123456
    }

    override var superclass: AnyClass? {
        // code
        return self as? AnyClass
    }

    override func `self`() -> Self {
        // code
        self
    }

    override func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        // code
        Unmanaged.passRetained(self)
    }

    override func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        // code
        Unmanaged.passRetained(self)
    }

    override func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        // code
        Unmanaged.passRetained(self)
    }

    override func isProxy() -> Bool {
        // code
        true
    }

    override func isKind(of aClass: AnyClass) -> Bool {
        // code
        true
    }

    override func isMember(of aClass: AnyClass) -> Bool {
        // code
        true
    }

    override func conforms(to aProtocol: Protocol) -> Bool {
        // code
        true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        // code
        true
    }

    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {

            mLineBusy = false
        }
        if call.isOutgoing == true && call.hasConnected == false {
            mLineBusy = true
        }
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            mLineBusy = true
        }

        if call.hasConnected == true && call.hasEnded == false {
            mLineBusy = true
        }
    }
}

@available(iOS 13.0, *)
extension VideoCallService: RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        // code
    }

    public func capturer(_ capturer: RTCCameraVideoCapturer, didCapture session: AVCaptureSession) {
        // code
    }

    public func capturer(_ capturer: RTCCameraVideoCapturer, didFailWithError error: Error) {
        // code
    }
}

//@available(iOS 13.0, *)

//class MyPeerConnectionCallback: NSObject {
//    var callback: CreatePeerConnectionCallback?
//
//    init(callback: CreatePeerConnectionCallback) {
//        print("init MyPeerConnectionCallback")
//        self.callback = callback
//    }
//}

@available(iOS 13.0, *)
extension VideoCallService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChangeStandardizedIceConnectionState newState: RTCIceConnectionState) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChangeLocalCandidate local: RTCIceCandidate, remoteCandidate remote: RTCIceCandidate, lastReceivedMs lastDataReceivedMs: Int32, changeReason reason: String) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        // code
        print("onSignalingChange:\(stateChanged)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // code
        print("onRemoveStream:\(stream)")
        if callback != nil {
            callback?.onRemoveStream(stream: stream)
        } else if callback2 != nil {
            callback2?.onRemoveStream(stream: stream)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        // code
        print("RTCMediaStream:\(stream)")
        if callback != nil {
            callback?.onAddStream(stream: stream)
        } else if callback2 != nil {
            callback2?.onAddStream(stream: stream)
        }
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // code
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        // code
        switch newState {
        case .new:
            print("onIceConnectionChange: new")
        case .checking:
            print("onIceConnectionChange: checking")
        case .connected:
            print("onIceConnectionChange: connected")
        case .completed:
            print("onIceConnectionChange: completed")
        case .failed:
            print("onIceConnectionChange: failed")
        case .disconnected:
            print("onIceConnectionChange: disconnected")
        case .closed:
            print("onIceConnectionChange: closed")
        case .count:
            print("onIceConnectionChange: count")
        @unknown default:
            print("onIceConnectionChange: unknown")
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        // code
        print("onIceGatheringChange:\(newState)")
        if newState == .complete {
            if callback != nil {
                callback?.onIceGatheringComplete()
            } else if callback2 != nil {
                callback2?.onIceGatheringComplete()
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // code
        print("onIceCandidate:\(candidate)")
        if callback != nil {
            callback?.onIceCandidate(candidate: candidate)
        } else if callback2 != nil {
            callback2?.onIceCandidate(candidate: candidate)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // code
        print("onIceCandidatesRemoved:\(candidates)")
        if callback != nil {
            callback?.onIceCandidatesRemoved(candidates: candidates)
        } else if callback2 != nil {
            callback2?.onIceCandidatesRemoved(candidates: candidates)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // code
    }

}