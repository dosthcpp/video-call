//
// Created by DOYEON BAEK on 2022/10/27.
//

import Foundation

class CallData {
        var name: String?
        var number: String?
        var status: CallStatusType?
        var date: String?
        var time: String?
        var bExpanded: Bool = false

    public init(name: String, number: String, status: CallStatusType, date: String, time: String) {
        self.name = name
        self.number = number
        self.status = status
        self.date = date
        self.time = time
    }

    func getDate() -> String {
        return self.date!
    }

    func getTime() -> String {
        return self.time!
    }

    func getStatus() -> CallStatusType {
        return self.status!
    }

    func getName() -> String {
        return self.name!
    }

    func getNumber() -> String {
        return self.number!
    }

    func setExpand(bExpanded: Bool) {
        self.bExpanded = bExpanded
    }

    func toggleExpand() {
        self.bExpanded = !self.bExpanded
    }

    func isExpanded() -> Bool {
        return self.bExpanded
    }
}