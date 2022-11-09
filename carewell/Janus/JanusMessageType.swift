//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

public enum JanusMessageType {
    case message
    case trickle
    case detach
    case destroy
    case keepalive
    case create
    case attach
    case event
    case error
    case ack
    case success
    case webrtcup
    case hangup
    case detached
    case media

    public func toString() -> String {
        switch self {
        case .message:
            return "message"
        case .trickle:
            return "trickle"
        case .detach:
            return "detach"
        case .destroy:
            return "destroy"
        case .keepalive:
            return "keepalive"
        case .create:
            return "create"
        case .attach:
            return "attach"
        case .event:
            return "event"
        case .error:
            return "error"
        case .ack:
            return "ack"
        case .success:
            return "success"
        case .webrtcup:
            return "webrtcup"
        case .hangup:
            return "hangup"
        case .detached:
            return "detached"
        case .media:
            return "media"
        }
    }

    public func equalsString(type: String) -> Bool {
        switch self {
        case .message:
            return type == "message"
        case .trickle:
            return type == "trickle"
        case .detach:
            return type == "detach"
        case .destroy:
            return type == "destroy"
        case .keepalive:
            return type == "keepalive"
        case .create:
            return type == "create"
        case .attach:
            return type == "attach"
        case .event:
            return type == "event"
        case .error:
            return type == "error"
        case .ack:
            return type == "ack"
        case .success:
            return type == "success"
        case .webrtcup:
            return type == "webrtcup"
        case .hangup:
            return type == "hangup"
        case .detached:
            return type == "detached"
        case .media:
            return type == "media"
        }
    }

    public static func fromString(string: String) -> JanusMessageType {
        switch string {
        case "message":
            return .message
        case "trickle":
            return .trickle
        case "detach":
            return .detach
        case "destroy":
            return .destroy
        case "keepalive":
            return .keepalive
        case "create":
            return .create
        case "attach":
            return .attach
        case "event":
            return .event
        case "error":
            return .error
        case "ack":
            return .ack
        case "success":
            return .success
        case "webrtcup":
            return .webrtcup
        case "hangup":
            return .hangup
        case "detached":
            return .detached
        case "media":
            return .media
        default:
            return .message
        }
    }
}