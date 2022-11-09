//
//  User.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/09/30.
//

import Foundation

class User {
    static var user: User?
//        id: Int(id), name: name, email: email, password: password
    var name: String?
    var number: String?
    var status: Int?
    var time: UInt64?

    init(name: String, number: String, status: Int, time: UInt64) {
        self.name = name
        self.number = number
        self.status = status
        self.time = time
    }

    fileprivate init() {}
    
    public func setName(name: String) {
        self.name = name
    }
    
    public func getName() -> String {
        if let name = self.name {
            return name
        }
        return ""
    }
    
    public static func getUser() -> User {
        if let user = self.user {
            return user
        } else {
            return User()
        }
    }
}
