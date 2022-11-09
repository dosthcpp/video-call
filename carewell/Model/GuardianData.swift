//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

class GuardianData {
    var silver_name: String?
    var number: String?
    var bExpanded: Bool = false

    init(silver_name: String?, number: String?) {
        self.silver_name = silver_name
        self.number = number
    }

    public init(name: String, number: String, bExpanded: Bool) {
        self.silver_name = name
        self.number = number
        self.bExpanded = bExpanded
    }

    public func getSilverName() -> String? {
        return silver_name
    }

    public func getNumber() -> String? {
        return number
    }

    public func setExpanded(bExpanded: Bool) {
        self.bExpanded = bExpanded
    }

    public func toggleExpanded() {
        bExpanded = !bExpanded
    }

    public func isExpanded() -> Bool {
        return bExpanded
    }
}
