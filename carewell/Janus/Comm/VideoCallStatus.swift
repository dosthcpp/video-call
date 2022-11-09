//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

enum VideoCallStatus {
    case UNKNOWN
    case IDLE

    case REGISTERED

    // UI 로 영상통화 시작을 요청할 때
    case MAKE
    case MAKE_EMERGENCY

    // 원격 장치 에 통화 요청 할 때
    case REQUEST
    case REQUEST_EMERGENCY

    case REQUEST_IN_PROCESS
    case ACCEPT
    case CANCEL
    case HANGUP

    case IN_CALL
    case REJECT
    case STOP
    case END
    case ROOM_CREATED
    case COMPLETE_CONNECT
    case NOTIFY_ITEM_INSERTED
    case NOTIFY_ITEM_DELETED
    case ERROR
    case BUSY

    func ordinal() -> Int {
        switch self {
        case .UNKNOWN:
            return 0
        case .IDLE:
            return 1
        case .REGISTERED:
            return 2
        case .MAKE:
            return 3
        case .MAKE_EMERGENCY:
            return 4
        case .REQUEST:
            return 5
        case .REQUEST_EMERGENCY:
            return 6
        case .REQUEST_IN_PROCESS:
            return 7
        case .ACCEPT:
            return 8
        case .CANCEL:
            return 9
        case .HANGUP:
            return 10
        case .IN_CALL:
            return 11
        case .REJECT:
            return 12
        case .STOP:
            return 13
        case .END:
            return 14
        case .ROOM_CREATED:
            return 15
        case .COMPLETE_CONNECT:
            return 16
        case .NOTIFY_ITEM_INSERTED:
            return 17
        case .NOTIFY_ITEM_DELETED:
            return 18
        case .ERROR:
            return 19
        case .BUSY:
            return 20
        }
    }
}
