//
//  LaunchScreenViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/25.
//

import UIKit
import FloatingPanel

protocol ServiceConnection {
    func onServiceConnected(name: ComponentName, service: Operation?)
    func onServiceDisconnected(name: ComponentName)
    func onBindingDied(name: ComponentName)
    func onNullBinding(name: ComponentName)
}

@available(iOS 13.0, *)
class LaunchScreenViewController: BaseViewController {

    var fpc: FloatingPanelController?
    var contentsViewController: TermsOfServiceViewController?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var operationQueue: OperationQueue?
    private var mVideoCallService: VideoCallService? = VideoCallService()

    fileprivate let GO_HOME: String = "go_home"

    private var mGlobalErrorCode: UInt64?
    private var alreadyLaunch = false

    // MARK: - override
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        Global.shared.setPhoneNumber(phoneNumber: "01026273086")
        let preferences = UserDefaults.standard
        let userPhoneNumberKey = "userPhoneNumber"
        let userPhoneNumber = preferences.string(forKey: userPhoneNumberKey)
        if userPhoneNumber != nil {
            Global.shared.setPhoneNumber(phoneNumber: userPhoneNumber!)
            initService()
        } else {
            // ask for userPhoneNumber
            let alert = UIAlertController(title: "최초 1회에 한해 전화번호를 입력합니다.", message: "본인의 휴대폰번호를 입력해주세요.", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "전화번호를 입력해주세요"
            }
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                Global.shared.setPhoneNumber(phoneNumber: textField!.text!)
                preferences.set(textField!.text!, forKey: userPhoneNumberKey)
                self.initService()
            }))
            DispatchQueue.main.async {[self] in
                present(alert, animated: true, completion: nil)
            }
        }


//        File().clear()
    }

    func initService() {
        if #available(iOS 13.0, *) {
            initMessageHandler()
        }
        initialize()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unbindVideoCallService()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == GO_HOME {
            if let destination = segue.destination as? MainTabbarController {
                let nav = destination.viewControllers?.first as? UINavigationController
                let vc = nav?.viewControllers.first as? HomeViewController
                vc?.mVideoCallService = mVideoCallService
                print("bound successfully!")
            }
        }
    }

    func destroyApp() {
        UIApplication.shared.perform(#selector((NSXPCConnection.suspend)))
    }

    private func showMessageBox(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { [self] (action) in
            destroyApp()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    func initialize() {
        // get identifier for vender
        DBHandler.initialize()
//        if phoneNum != nil {
//            if !(phoneNum == UserProperties.getUserName()) {
//                UserProperties.removeAll()
//                DBHandler.deleteAll()
//            }
//            UserProperties.setUserNumber(userNumber: phoneNum)
//            mUserID = phoneNum
//        }
        if let serial_no = UIDevice.current.identifierForVendor {
            // get the last 1 character of the identifier
            let lastChar = serial_no.uuidString.suffix(1)
            let phoneNum = "0113774268\(String((UInt32(lastChar, radix: 16) ?? 0) % 10))"
            UserProperties.setUserName(phoneNum)
        }

        startServiceIfNone()
    }

    class VideoCallServiceCallback: IVideoCallServiceCallback {
        var id: String
        var context: NSObject?

        init(context: LaunchScreenViewController) {
            id = "kr.co.carewell.videocall.service.callback"
            self.context = context
        }

        func onDataChangedInd(what_data: String) {
        }

        func onStatusInd(status: String, statusCode: Int) {

        }

        func onMessageReceived(msg_type: String, msg: String, sdata: String, fdata: Float, idata: Int, bdata: Bool, from: String) {
            if msg_type == MsgTypeConfig.TYPE_VIDEO_CALL, let context = context as? LaunchScreenViewController {
                print("SVC:oMR:TYPE_VIDEO_CALL:\(from), idata:\(idata)");
                context.sendInternalMessage_VideoCall_Status(callData: sdata, status: idata, from: from);
            }
        }
    }

    private func startServiceIfNone() {
        if let mVideoCallService = mVideoCallService {
            if !mVideoCallService.isExecuting {
//                operationQueue = OperationQueue()
//                operationQueue?.addOperations([mVideoCallService], waitUntilFinished: false)
                mVideoCallService.start()
            }
        }
        bindVideoCallService()
    }

    private lazy var mVideoCallServiceCallback: VideoCallServiceCallback = VideoCallServiceCallback(context: self)

    @available(iOS 13.0, *)
    private func bindVideoCallService() {
        if let isBound = mVideoCallService?.isReady as? Bool {
            if isBound {
                if let cancelled = mVideoCallService?.isCancelled as? Bool {
                    if !cancelled {
                        mVideoCallService?.registerCallback(cb: mVideoCallServiceCallback)
                        if let hasUserInfo = mVideoCallService?.hasUserInfoo() as? Bool {
                            if !hasUserInfo {
                                sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Get_UserInfo, delay: 10)
                            } else if let registered = mVideoCallService?.isRegistered() as? Bool, registered {
                                mMessageHandler?.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKeySplash, object: ["what": LaunchScreenViewController.Msg_Failed_ConnectServer]), coalesceMask: 0)
                                if !alreadyLaunch {
                                    startActivity()
                                    alreadyLaunch = true
                                }
                            }
                        }
                    } else {
                        // if cancelled
                        if mVideoCallService != nil {
                            mVideoCallService = nil
                        }
                    }
                }
            } else {
                sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Service_ReConnect, delay: 2000)
            }
        }
    }

    private func unbindVideoCallService() {
        mVideoCallService?.unregisterCallback(cb: mVideoCallServiceCallback)
        mVideoCallService = nil
    }

    private static var Msg_Get_UserInfo: Int = 100
    private static var Msg_Verified_User: Int = 101
    private static var Msg_Video_Call_Status: Int = 130
    private static var Msg_Close_CalleeDialog: Int = 330
    private static var Msg_Show_Message: Int = 400
    private static var Msg_Hangup_Called: Int = 700
    private static var Msg_Show_ErrorBox: Int = 800
    private static var Msg_Service_ReConnect: Int = 900
    private static var Msg_Failed_ConnectServer: Int = 1000
    private static var Msg_Check_DeviceValidty: Int = 1100
    private static var Msg_Service_Connect: Int = 1200

    let center = NotificationCenter.default
    var mMessageHandler: NotificationQueue? = NotificationQueue.default

    @available(iOS 13.0, *)
    func initMessageHandler() {
        center.addObserver(self, selector: #selector(handleMessage(_:)), name: Notification.Name.myNotificationKeySplash, object: nil)
    }

    @available(iOS 13.0, *)
    @objc func handleMessage(_ notification: Notification) {
        if let msg = notification.object as? [String: Any], let what = msg["what"] as? Int {
            if what == LaunchScreenViewController.Msg_Service_ReConnect {
                bindVideoCallService()
            } else if what == LaunchScreenViewController.Msg_Get_UserInfo {
                print("사용자 정보를 확인중입니다...")
                if let mVideoCallService = mVideoCallService {
                    mVideoCallService.setUserInfoFlag(bHave: false)
                }

                var m_nRetryConnectCount = 0;

                let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/get_guardian_info_phone")!
                InfomarkClient().postWithErrorHandling(param: [
                    "silver_guardian_tel": Global.shared.getPhoneNumber()
                ] as Dictionary, url: url, runnable: { [self] json in
                    let jsonObject = json as! NSDictionary
                    if let state = jsonObject["state"] as? String {
                        if (state == "ok") {
                            let objCArray = NSMutableArray(object: jsonObject["silver_list"]!)
                            if let swiftArray = objCArray as NSArray? as? [Any] {
                                for i in 0...swiftArray.count - 1 {
                                    if let jsonArray = swiftArray[i] as? [[String: Any]], let mVideoCallService = mVideoCallService, let guardianList = mVideoCallService.mGuardiansList as? [GuardianData] {
                                        var index = 0
                                        while index < jsonArray.count {
                                            guard let guardianObject = jsonArray[index] as [String: Any]? else {
                                                break
                                            }

                                            if let silver_sn = guardianObject["silver_ai_speaker_id"] as? String, let guardian_name = guardianObject["silver_guardian_name"] as? String, let silver_name = guardianObject["silver_name"] as? String {
                                                UserProperties.setParentNumber(phoneNumber: silver_sn)
                                                UserProperties.setUserName(guardian_name)
                                                UserProperties.setParentName(userName: silver_name)
                                                // add guardian name
                                                mVideoCallService.mGuardiansList?.append(GuardianData(name: silver_name, number: silver_sn, bExpanded: (index == 0) ? true : false))
                                                index += 1
                                            }

                                            m_nRetryConnectCount = 0
                                            onServerResult(id: 1)
                                        }
                                    }
                                }
                            }

                        } else if (state == "fail") {
                            UserProperties.setParentNumber(phoneNumber: "")
                            onServerResult(id: 0)
                        } else {
                            m_nRetryConnectCount += 1
                            if m_nRetryConnectCount <= 3 {
                                onServerResult(id: -1)
                            } else {
                                onServerResult(id: -2)
                            }
                        }
                    }
                }, errorRunnable: { [self] (error) in
                    if let error = error as? Error {
                        m_nRetryConnectCount += 1
                        if m_nRetryConnectCount <= 3 {
                            onServerResult(id: -1)
                        } else {
                            onServerResult(id: -2)
                        }
                    }
                })
            } else if what == LaunchScreenViewController.Msg_Service_Connect {
                if let mVideoCallService = mVideoCallService {
                    print("영상통화 서버에 접속중입니다...")
                    startServiceIfNone()
                    sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Failed_ConnectServer, delay: 15000)
                }
            } else if what == LaunchScreenViewController.Msg_Show_Message, let arg = msg["arg1"] as? String {
//                mMessage.setText(msg.arg1);
                print(arg)
            } else if what == LaunchScreenViewController.Msg_Show_ErrorBox {
                showMessageBox(message: "서버에 접속할 수 없습니다.\n잠시 후 다시 시도해 주세요.")
            } else if what == LaunchScreenViewController.Msg_Verified_User {
                if let arg = msg["arg1"] as? String {
                    showCertFloatingPanel()
                } else {
                    showMessageBox(message: "등록되지 않은 사용자입니다.\n담당자에게 문의하세요.")
                }
            } else if what == LaunchScreenViewController.Msg_Video_Call_Status {
                if let status = msg["arg1"] as? Int, let data = msg["obj"] as? [String] {
                    if status == VideoCallStatus.ERROR.ordinal() {
                        mGlobalErrorCode = UInt64(data[0])
                    } else if status == VideoCallStatus.REGISTERED.ordinal() {
                        mMessageHandler?.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKeySplash, object: ["what": LaunchScreenViewController.Msg_Failed_ConnectServer]), coalesceMask: 0)
                        if UserProperties.isCertified() {
                            if !alreadyLaunch {
                                startActivity()
                                alreadyLaunch = true
                            }
                        } else {
                            // 프로퍼티 팡리이 앱 지울떄 같이 지워져버림
                            UserProperties.setCertified(isCertified: true)
                            if !alreadyLaunch {
                                startActivity()
                                alreadyLaunch = true
                            }
                        }
                    }
                }
            } else if what == LaunchScreenViewController.Msg_Failed_ConnectServer {
                print("영상통화 서버에 접속할 수 없습니다....잠시후에 다시 시도해 주세요.")
            } else if what == LaunchScreenViewController.Msg_Show_ErrorBox {

            } else if what == LaunchScreenViewController.Msg_Hangup_Called {

            } else if what == LaunchScreenViewController.Msg_Close_CalleeDialog {

            }
        }
    }

    private var mUserID: String?;

    func onServerResult(id: Int) {
        if id == 0 {
            sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Show_ErrorBox, status: "등록되지 않은 사용자입니다.담당자에게 문의하세요.", delay: 10)
        } else if id == 1 {
            if let mVideoCallService = mVideoCallService {
                mVideoCallService.setUserInfoFlag(bHave: true)
            }

//            if true {
            if UserProperties.isCertified() {
                if let mVideoCallService = mVideoCallService, mVideoCallService.isRegistered() {
                    mMessageHandler?.dequeueNotifications(matching: Notification(name: Notification.Name.myNotificationKeySplash, object: ["what": LaunchScreenViewController.Msg_Failed_ConnectServer]), coalesceMask: 0)
                    if !alreadyLaunch {
                        startActivity()
                        alreadyLaunch = true
                    }
                } else if let mVideoCallService = mVideoCallService {
                    sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Service_Connect, delay: 10)
                }
            } else {
                print("인증이 필요합니다.")
                showCertFloatingPanel()
            }
        } else if id == -1 {
            sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Get_UserInfo, delay: 3000)
        } else if id == -2 {
            sendInternalMessageDelayed(what: LaunchScreenViewController.Msg_Show_ErrorBox, status: "사용자 정보 취득실패.잠시후에 다시 시도해 주세요.", delay: 10)
        }
    }

    private func sendInternalMessageDelayed(what: Int, delay: Int) {
        if let mMessageHandler = mMessageHandler {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0)) {
                mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeySplash, object: ["what": what]), postingStyle: .now)
            }
        }
    }

    private func sendInternalMessageDelayed(what: Int, status: String, delay: Int) {
        if let mMessageHandler = mMessageHandler {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0)) {
                mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeySplash, object: ["what": what, "arg1": status]), postingStyle: .now)
            }
        }
    }

    private func sendInternalMessage_VideoCall_Status(callData: String, status: Int, from: String) {
        if let mMessageHandler = mMessageHandler {
            mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeySplash, object: ["obj": [callData, from], "what": LaunchScreenViewController.Msg_Video_Call_Status, "arg1": status]), postingStyle: .now)
        }
    }

    // MARK: - function

    func startActivity() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.performSegue(withIdentifier: self.GO_HOME, sender: nil)
        }
    }

    private func showCertFloatingPanel() {
        guard let contentsViewController = storyboard?.instantiateViewController(identifier: "UserCertViewController", creator: { (coder) -> UserCertViewController? in
            return UserCertViewController(coder: coder)
        })
        else {
            return
        }
        fpc = FloatingPanelController()
        if let fpc = fpc {
            fpc.delegate = self
            fpc.layout = MyFloatingPanelLayout()
            fpc.set(contentViewController: contentsViewController)
//            fpc.addPanel(toParent: self)
            present(fpc, animated: true, completion: nil)
        }
    }
}

@available(iOS 13.0, *)
extension LaunchScreenViewController: FloatingPanelControllerDelegate {

}

class MyFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition {
        return .bottom
    }

    var initialState: FloatingPanelState {
        return .full
    }

    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] { // 가능한 floating panel: 현재 full, half만 가능하게 설정
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 292, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
}
