//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation
import UIKit

extension String {
    func utf8DecodedString()-> String {
        let data = self.data(using: .utf8)
        let message = String(data: data!, encoding: .nonLossyASCII) ?? ""
        return message
    }

    func utf8EncodedString()-> String {
        let messageData = self.data(using: .nonLossyASCII)
        let text = String(data: messageData!, encoding: .utf8) ?? ""
        return text
    }

    func customEncodedString()-> String {
        let messageData = self.data(using: .nonLossyASCII)
        let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0422))
        let text = String(data: messageData!, encoding: encoding) ?? ""
        print("encoded String: \(text)")
        return text
    }

    func customDecodedString()-> String {
        let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0422))
        let messageData = self.data(using: encoding)
        let text = String(data: messageData!, encoding: .nonLossyASCII) ?? ""
        return text
    }
}

public class UserProperties {

    public static var PROPERTY_USER_CERT: String = "healthcare.user.certifiied"
    public static var PROPERTY_CAPABILITIES: String = "healthcare.user.capabilities"
    public static var PROPERTY_APP_UUID: String = "healthcare.app.uuid"

    public static var PROPERTY_USER_ID: String = "healthcare.user.id"
    public static var PROPERTY_USER_NAME: String = "healthcare.user.name"
    public static var PROPERTY_USER_NUMBER: String = "healthcare.user.number"
    public static var PROPERTY_PARENT_NAME: String = "healthcare.parent.name"
    public static var PROPERTY_PARENT_NUMBER: String = "healthcare.parent.number"
    public static var PROPERTY_CALLEE_NAME: String = "healthcare.callee.name"
    public static var PROPERTY_USER_AGREEMENT: String = "healthcare.user.agreement"
    public static var PROPERTY_USER_SERVICE_END: String = "healthcare.user.service_endtime"

    public static var PROPERTY_ANNOUNCEMENT: String = "healthcare.user.announcement"
    public static var PROPERTY_GUARDIAN1_NAME: String = "healthcare.user.guardian1.name"
    public static var PROPERTY_GUARDIAN1_NUM: String = "healthcare.user.guardian1.num"
    public static var PROPERTY_GUARDIAN1_NICK: String = "healthcare.user.guardian1.nick"
    public static var PROPERTY_GUARDIAN2_NAME: String = "healthcare.user.guardian2.name"
    public static var PROPERTY_GUARDIAN2_NUM: String = "healthcare.user.guardian2.num"
    public static var PROPERTY_GUARDIAN2_NICK: String = "healthcare.user.guardian2.nick"

    public static var PROPERTY_NOTICE_NUM: String = "healthcare.user.notice_num"

    public static func clearAll() {
        setCertified(isCertified: false)
        setUserID("")
        setUserName("")
        setAgreement("")
    }

    public static func removeAll() {
        setUserID("")
        setUserName("")
        setAgreement("")
    }

    private init() {
    }

    public static func isCertified() -> Bool {
        var isCert: Bool = LocalProperties.get(PROPERTY_USER_CERT, false)
        print("isCertified: \(isCert == true)")
        return isCert
    }

    public static func setCertified(isCertified: Bool) {
        LocalProperties.set(PROPERTY_USER_CERT, isCertified)
    }

    public static func getCallable() -> Bool {
        let isCert = LocalProperties.get(PROPERTY_CAPABILITIES, false)
        return isCert
    }

    public static func setCallable(bCallable: Bool) {
        LocalProperties.set(PROPERTY_CAPABILITIES, bCallable)
    }

    public static func getUserID() -> String {
        let user_id = LocalProperties.get(PROPERTY_USER_ID, "")
        return user_id
    }

    public static func setUserID(_ userID: String) {
        LocalProperties.set(PROPERTY_USER_ID, userID)
    }

    public static func getUserName() -> String {
        var userName = LocalProperties.get(PROPERTY_USER_NAME, "")
        return userName
    }

    public static func setUserName(_ userName: String) {
        LocalProperties.set(PROPERTY_USER_NAME, userName)
    }

    public static func getUserNumber() -> String {
        var userName = LocalProperties.get(PROPERTY_USER_NUMBER, "")
        #if DEBUG
        return Global.shared.getPhoneNumber()
        #else
        return userName
        #endif
    }

    public static func setUserNumber(userNumber: String) {
        LocalProperties.set(PROPERTY_USER_NUMBER, userNumber)
    }

    public static func setParentName(userName: String) {
        LocalProperties.set(PROPERTY_PARENT_NAME, userName)
    }

    public static func getParentName() -> String {
        return LocalProperties.get(PROPERTY_PARENT_NAME, "")
    }

    public static func setParentNumber(phoneNumber: String) {
        LocalProperties.set(PROPERTY_PARENT_NUMBER, phoneNumber)
    }

    public static func getParentNumber() -> String {
        return LocalProperties.get(PROPERTY_PARENT_NUMBER, "")
    }

    public static func getCalleeName() -> String {
        var userName = LocalProperties.get(PROPERTY_CALLEE_NAME, "")
        return userName
    }

    public static func setCalleeName(userName: String) {
        LocalProperties.set(PROPERTY_CALLEE_NAME, userName)
    }

    public static func getAppUUID() -> String {
        let uuid = LocalProperties.get(PROPERTY_APP_UUID, "")
        if !uuid.isEmpty {
            return uuid
        }
        return UIDevice.current.identifierForVendor?.uuidString ?? "02:00:00:00:00:00"
    }

    public static func setAppUUID(uuid: String) {
        LocalProperties.set(PROPERTY_APP_UUID, uuid)
    }


    public static func getAgreement() -> String {
        var agreement = LocalProperties.get(PROPERTY_USER_AGREEMENT, "")
        return agreement
    }

    public static func setAgreement(_ agreement: String) {
        LocalProperties.set(PROPERTY_USER_AGREEMENT, agreement)
    }

    public static func getServiceEndTime() -> String {
        var durDate = LocalProperties.get(PROPERTY_USER_SERVICE_END, "")
        return durDate
    }

    public static func setServiceEndTime(dueDate: String) {
        LocalProperties.set(PROPERTY_USER_SERVICE_END, dueDate)
    }

    public static func addAnnoucement() {
        var announceNum = getAnnouncement()
        announceNum = announceNum + 1
        LocalProperties.set(PROPERTY_ANNOUNCEMENT, announceNum)
    }

    public static func setAnnoucement(announceNum: Int) {
        LocalProperties.set(PROPERTY_ANNOUNCEMENT, announceNum)
    }

    public static func getAnnouncement() -> Int {
        return LocalProperties.get(PROPERTY_ANNOUNCEMENT, 0)
    }

    public static func getGuardian1Name() -> String {
        var agreement = LocalProperties.get(PROPERTY_GUARDIAN1_NAME, "")
        return agreement
    }

    public static func setGuardian1Name(name: String) {
        LocalProperties.set(PROPERTY_GUARDIAN1_NAME, name)
    }

    public static func getGuardian1Number() -> String {
        var agreement = LocalProperties.get(PROPERTY_GUARDIAN1_NUM, "")
        return agreement
    }

    public static func setGuardian1Number(name: String) {
        LocalProperties.set(PROPERTY_GUARDIAN1_NUM, name)
    }

    public static func getGuardian1Nick() -> String {
        var agreement: String = LocalProperties.get(PROPERTY_GUARDIAN1_NICK, "")
        return agreement
    }

    public static func setGuardian1Nick(name: String) {
        LocalProperties.set(PROPERTY_GUARDIAN1_NICK, name)
    }

    public static func getGuardian2Name() -> String {
        var agreement = LocalProperties.get(PROPERTY_GUARDIAN2_NAME, "")
        return agreement
    }

    public static func setGuardian2Name(name: String) {
        LocalProperties.set(PROPERTY_GUARDIAN2_NAME, name)
    }

    public static func getGuardian2Number() -> String {
        var agreement = LocalProperties.get(PROPERTY_GUARDIAN2_NUM, "")
        return agreement
    }

    public static func setGuardian2Number(name: String) {
        LocalProperties.set(PROPERTY_GUARDIAN2_NUM, name)
    }

    public static func getGuardian2Nick() -> String {
        var agreement = LocalProperties.get(PROPERTY_GUARDIAN2_NICK, "")
        return agreement
    }

    public static func setGuardian2Nick(name: String) {
        LocalProperties.set(PROPERTY_GUARDIAN2_NICK, name)
    }

    public static func addNotice() {
        var curNotice = getNoticeNum()
        curNotice += 1
        LocalProperties.set(PROPERTY_NOTICE_NUM, curNotice)
    }

    public static func getNoticeNum() -> Int {
        return LocalProperties.get(PROPERTY_NOTICE_NUM, 0)
    }

    public static func setNoticeNum(announceNum: Int) {
        LocalProperties.set(PROPERTY_NOTICE_NUM, announceNum)
    }

    public static func clearMissedCall() {
        LocalProperties.set(PROPERTY_NOTICE_NUM, 0)
    }

}