//
// Created by DOYEON BAEK on 2022/10/22.
//

import Foundation

enum CallStatusType: Int {
    case REJECT = 0
    case ABSENCE = 1
    case RECEIVE = 2
    case OUTGOING = 3

    func parseRawValue(_ status: Int) -> CallStatusType {
        switch status {
        case 0:
            return .REJECT
        case 1:
            return .ABSENCE
        case 2:
            return .RECEIVE
        case 3:
            return .OUTGOING
        default:
            return .REJECT
        }
    }

    func getRawValue() -> Int {
        switch self {
        case .REJECT:
            return 0
        case .ABSENCE:
            return 1
        case .RECEIVE:
            return 2
        case .OUTGOING:
            return 3
        }
    }
}

extension CallStatusType {
    private static var id: Int?

    public func getId() -> Int {
        return CallStatusType.id!
    }

    public static func fromId(id: Int) -> CallStatusType {
        switch id {
        case 0:
            return CallStatusType.REJECT
        case 1:
            return CallStatusType.ABSENCE
        case 2:
            return CallStatusType.RECEIVE
        case 3:
            return CallStatusType.OUTGOING
        default:
            return CallStatusType.REJECT
        }
    }
}