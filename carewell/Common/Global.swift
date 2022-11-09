//
// Created by DOYEON BAEK on 2022/11/09.
//

import Foundation

class Global {
    static let shared = Global()
    var phoneNumber: String = ""

    func getPhoneNumber() -> String {
        return phoneNumber
    }

    func setPhoneNumber(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }
}