//
//  UserCertViewController.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/25.
//

import Foundation
import UIKit

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

class UserCertViewController: BaseViewController {

    private var show_detail_1 = "show_detail_1"
    private var show_detail_2 = "show_detail_2"
    private var show_detail_3 = "show_detail_3"

    @IBOutlet var agreeBtn1: UIButton!
    @IBOutlet var agreeBtn2: UIButton!
    @IBOutlet var agreeBtn3: UIButton!

    @IBOutlet var showDetailBtn1: UIButton!
    @IBOutlet var showDetailBtn2: UIButton!
    @IBOutlet var showDetailBtn3: UIButton!

    @IBAction func onTapDetailBtn1(_ sender: Any) {
    }

    @IBAction func onTapDetailBtn2(_ sender: Any) {
    }

    @IBAction func onTapDetailBtn3(_ sender: Any) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let identifier = segue.identifier {
            switch identifier {
            case show_detail_1:
                if let vc = segue.destination as? TermsOfServiceViewController {
                    if let path = Bundle.main.path(forResource: "terms_conditions", ofType: "htm") {
                        do {
                            let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0422))
                            let html = try String(contentsOfFile: path, encoding: encoding)
                            vc.contentString = html.htmlToAttributedString
                        } catch {
                            print("error: \(error)")
                        }
                    }
                }
            case show_detail_2:
                if let vc = segue.destination as? TermsOfServiceViewController {
                    if let path = Bundle.main.path(forResource: "personal_policy", ofType: "htm") {
                        do {
                            let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0422))
                            let html = try String(contentsOfFile: path, encoding: encoding)
                            vc.contentString = html.htmlToAttributedString
                        } catch {
                            print("error: \(error)")
                        }
                    }
                }
            case show_detail_3:
                if let vc = segue.destination as? TermsOfServiceViewController {
                    if let path = Bundle.main.path(forResource: "lorem_ipsum", ofType: "htm") {
                        do {
                            let html = try String(contentsOfFile: path, encoding: .utf8)
                            vc.contentString = html.htmlToAttributedString
                        } catch {
                            print("error: \(error)")
                        }
                    }
                }
            default:
                break
            }
        }
    }

    @IBAction func onAgreeBtn1Clicked(_ sender: Any) {
        agreeBtn1.isSelected = !agreeBtn1.isSelected
        if agreeBtn1.isSelected && agreeBtn2.isSelected && agreeBtn3.isSelected {
            confirmBtn.backgroundColor = UIColor(rgb: 0xF03E00)
            confirmBtn.isEnabled = true
        } else {
            confirmBtn.isEnabled = false
        }
    }


    @IBAction func onAgreeBtn2Clicked(_ sender: Any) {
        agreeBtn2.isSelected = !agreeBtn2.isSelected
        if agreeBtn1.isSelected && agreeBtn2.isSelected && agreeBtn3.isSelected {
            confirmBtn.backgroundColor = UIColor(rgb: 0xF03E00)
            confirmBtn.isEnabled = true
        } else {
            confirmBtn.isEnabled = false
        }
    }


    @IBAction func onAgreeBtn3Clicked(_ sender: Any) {
        agreeBtn3.isSelected = !agreeBtn3.isSelected
        if agreeBtn1.isSelected && agreeBtn2.isSelected && agreeBtn3.isSelected {
            confirmBtn.backgroundColor = UIColor(rgb: 0xF03E00)
            confirmBtn.isEnabled = true
        } else {
            confirmBtn.isEnabled = false
        }
    }


    @IBAction func onConfirmBtnClicked(_ sender: Any) {
        sendInternalMessageDelayed(what: UserCertViewController.Msg_Get_UserInfo, delay: 3000)
    }

    @IBOutlet var confirmBtn: UIButton!

    override func viewDidLoad() {
        agreeBtn1.setImage(UIImage(named: "btn_disabled"), for: .normal)
        agreeBtn1.setImage(UIImage(named: "ic_check_selected"), for: .selected)

        agreeBtn2.setImage(UIImage(named: "btn_disabled"), for: .normal)
        agreeBtn2.setImage(UIImage(named: "ic_check_selected"), for: .selected)

        agreeBtn3.setImage(UIImage(named: "btn_disabled"), for: .normal)
        agreeBtn3.setImage(UIImage(named: "ic_check_selected"), for: .selected)

        confirmBtn.backgroundColor = UIColor(rgb: 0xA7A7A7)
        confirmBtn.setTitleColor(UIColor.white, for: .disabled)
        confirmBtn.setTitleColor(UIColor.white, for: .normal)
        // remove title
        showDetailBtn1.setTitle("", for: .normal)
        showDetailBtn2.setTitle("", for: .normal)
        showDetailBtn3.setTitle("", for: .normal)

        confirmBtn.cornerRadius = 25
        confirmBtn.isEnabled = false

        if #available(iOS 13.0, *) {
            initMessageHandler()
        }
    }

    @available(iOS 13.0, *)
    func initMessageHandler() {
        center.addObserver(self, selector: #selector(handleMessage(_:)), name: Notification.Name.myNotificationKeyCert, object: nil)
    }

    let center = NotificationCenter.default
    var mMessageHandler: NotificationQueue? = NotificationQueue.default

    private static var Msg_ShowMessage = 100
    private static var Msg_Get_UserInfo = 200
    private static var Msg_Goto_BatteryOpt = 300

    @available(iOS 13.0, *)
    @objc func handleMessage(_ notification: Notification) {
        if let msg = notification.object as? [String: Any], let what = msg["what"] as? Int {
            if what == UserCertViewController.Msg_ShowMessage {
                if let arg1 = msg["arg1"] as? String {
                    showMessageBox(message: arg1)
                }
            } else if what == UserCertViewController.Msg_Goto_BatteryOpt {
                let lowPowerDisabled = ProcessInfo.processInfo.isLowPowerModeEnabled == false
                if lowPowerDisabled {
                    self.dismiss(animated: true)
                } else {
                    sendInternalMessage(what: UserCertViewController.Msg_ShowMessage, arg1: "저전력 모드가 켜져있습니다. 설정 > 배터리 > 배터리 성능 상태 > 최적화된 배터리 충전에서 저전력 모드를 해제해주세요.")
                }
            } else if what == UserCertViewController.Msg_Get_UserInfo {
                var m_nRetryConnectCount = 0

                let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/guardian_agree_with_policy")!
                InfomarkClient().postWithErrorHandling(param: [
                    "guardian_id": Global.shared.getPhoneNumber()
                ] as Dictionary, url: url, runnable: { [self] json in
                    let jsonObject = json as! NSDictionary

                    if let state = jsonObject["state"] as? String {
                        if (state == "ok") {
                            m_nRetryConnectCount = 0
                            onServerResult(id: 1)
                        } else if (state == "fail") {
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
            }
        }
    }

    private func onServerResult(id: Int) {
        if id == 0 {
            sendInternalMessage(what: UserCertViewController.Msg_ShowMessage, arg1: "정보 처리 오류!!!\n고객센터에 문의하세요.")
        } else if id == 1 {
            UserProperties.setCertified(isCertified: true)
            UserProperties.setAppUUID(uuid: UUID().uuidString)
            sendInternalMessageDelayed(what: UserCertViewController.Msg_Goto_BatteryOpt, delay: 1)
        } else if id == -1 {
            sendInternalMessageDelayed(what: UserCertViewController.Msg_Get_UserInfo, delay: 3000)
        } else if id == -2 {
            sendInternalMessage(what: UserCertViewController.Msg_ShowMessage, arg1: "서버 접속 오류!!!\n잠시후에 다시 시도해 주세요.")
        }
    }

    private func sendInternalMessage(what: Int, arg1: String) {
        if let mMessageHandler = mMessageHandler {
            mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyCert, object: ["what": what, "arg1": arg1]), postingStyle: .now)
        }
    }

    private func sendInternalMessageDelayed(what: Int, delay: Int) {
        if let mMessageHandler = mMessageHandler {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(delay) / 1000.0)) {
                mMessageHandler.enqueue(Notification(name: Notification.Name.myNotificationKeyCert, object: ["what": what]), postingStyle: .now)
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
}
