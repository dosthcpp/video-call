//
// Created by DOYEON BAEK on 2022/10/20.
//

// TODO: implement VideoCallService/JanusClient

import Foundation
import WebRTC

public protocol JanusCallback {
    func onCreateSession(_ sessionId: Decimal)
    func onAttached(_ handleId: Decimal)
    func onSubscribeAttached(_ subscribeHandleId: Decimal, _ feedId: Decimal)
    func onDetached(_ handleId: Decimal, reason: String?)
    func onHangup(_ handleId: Decimal)
    func onMessage(_ sender: Decimal, _ handleId: Decimal, _ msg: Any, _ jsep: Any)
    func onIceCandidate(_ handleId: Decimal, _ candidate: Any)
    func onDestroySession(_ sessionId: Decimal)
    func onError(_ error: String)
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}

extension Float {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

@available(iOS 13.0, *)
public class JanusClient: WebSocketCallback {

    let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0422))

    private var attachedPlugins: ConcurrentHashMap = ConcurrentHashMap()
    private var transactions: ConcurrentHashMap = ConcurrentHashMap()
    private var sessionId: Decimal?
    private var janusCallback: JanusCallback?

    public var isKeepAliveRunning: Volatile<Bool>?
    private var keepAliveThread: Thread?
    private var janusUrl: String?
    private var webSocketChannel: WebSocketChannel?
    private var macAddress: String?

    public init(janusUrl: String, macAddress: String?) {
        self.janusUrl = janusUrl
        if let macAddress = macAddress {
            self.macAddress = macAddress
        }
        webSocketChannel = WebSocketChannel()
        webSocketChannel?.setWebSocketCallback(webSocketCallback: self)
    }

    public func setJanusCallback(janusCallback: JanusCallback?) {
        if let janusCallback = janusCallback {
            self.janusCallback = janusCallback
        }
    }

    public func connect() {
        webSocketChannel?.connect(url: janusUrl!)
    }

    public func disconnect() {
        stopKeepAliveTimer()
        if webSocketChannel != nil {
            webSocketChannel?.close()
            webSocketChannel = nil
        }
    }

    public func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in
            letters.randomElement()!
        })
    }

    private func createSession() {
        let tid = randomString(length: 12)

        class MyTransAction: Transaction {
            var janusClient: JanusClient

            public init(_ janusClient: JanusClient, _ tid: String) {
                self.janusClient = janusClient
                super.init(tid: tid, feedId: nil, context: janusClient)
            }

            override func onSuccess(data msg: Any) throws {
                if let msg = msg as? [String: Any] {
                    guard let data = msg["data"] as? [String: Any] else {
                        return
                    }
                    print("onSuccess!!!! with data: \(data)")
                    if let sessionId = data["id"] as? UInt64 {
                        janusClient.sessionId = Decimal(sessionId)
                    }
                    if let janusCallback = janusClient.janusCallback, let sessionId = janusClient.sessionId {
                        janusCallback.onCreateSession(sessionId)
                    }
                }
            }
        }

        transactions.put(key: tid, value: MyTransAction(self, tid))
        var obj: Dictionary<String, Any> = [:]
        obj["janus"] = "create"
        obj["mac"] = macAddress
        obj["transaction"] = tid
        if let json = try? JSONSerialization.data(
                withJSONObject: obj,
                options: [.withoutEscapingSlashes]) {
            let obj = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: obj!)
        }
    }

    public func destroySession() {
    }

    public func destroyOldSession() {
    }

    public func attachPlugin(pluginName: String) {
        let tid = randomString(length: 12)

        class MyTransAction: Transaction {
            var janusClient: JanusClient

            public init(_ janusClient: JanusClient, _ tid: String) {
                self.janusClient = janusClient
                super.init(tid: tid, feedId: nil, context: janusClient)
            }

            override func onSuccess(data msg: Any) throws {
//                let data = (msg as? Dictionary<String, Any>)!["data"]
//                let handleId = (data as? Dictionary<String, Any>)!["id"] as? Decimal
//                if janusClient.janusCallback != nil, let handleId = handleId {
//                    janusClient.janusCallback?.onAttached(handleId)
//                }
                if let msg = msg as? [String: Any] {
                    guard let data = msg["data"] as? [String: Any] else {
                        return
                    }
                    print("onSuccess!!!! with data: \(data)")
                    if let handleId = data["id"] as? UInt64 {
                        if janusClient.janusCallback != nil {
                            janusClient.janusCallback?.onAttached(Decimal(handleId))
                        }
                        let handle = PluginHandle(handleId: Decimal(handleId))
                        janusClient.attachedPlugins.put(key: "\(Decimal(handleId))", value: handle)
                    }
                }
            }
        }

        transactions.put(key: tid, value: MyTransAction(self, tid))

        var obj: Dictionary<String, Any> = [:]
        obj["janus"] = "attach"
        obj["transaction"] = tid
        obj["plugin"] = pluginName
        obj["session_id"] = sessionId
        if let json = try? JSONSerialization.data(
                withJSONObject: obj,
                options: [.withoutEscapingSlashes]) {
            let obj = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: obj!)
        }
    }

    public func subscribeAttach(feedId: Decimal) {
        var tid = randomString(length: 12)

        class MyTransAction: Transaction {
            var janusClient: JanusClient

            public init(_ janusClient: JanusClient, _ tid: String, _ feedId: Decimal) {
                self.janusClient = janusClient
                super.init(tid: tid, feedId: feedId, context: janusClient)
            }

            override func onSuccess(data msg: Any, feed: Decimal) throws {
                let data = (msg as? Dictionary<String, Any>)!["data"]
                if let handleId = (data as? Dictionary<String, Any>)!["id"] as? NSNumber, let handleIdDecimal = Decimal(string: handleId.stringValue) {
                    print("onSuccess!!!! with handleId: \(handleId)")
                    if handleId == nil {
                        print((data as? Dictionary<String, Any>)!["id"])
                    }
                    if janusClient.janusCallback != nil {
                        janusClient.janusCallback?.onSubscribeAttached(handleIdDecimal, feed)
                    }
                    let handle = PluginHandle(handleId: handleIdDecimal)
                    janusClient.attachedPlugins.put(key: "\(handleId.decimalValue)", value: handle)
                }
            }
        }

        transactions.put(key: tid, value: MyTransAction(self, tid, feedId))

        var obj: Dictionary<String, Any> = [:]
        obj["janus"] = "attach"
        obj["transaction"] = tid
        obj["plugin"] = "janus.plugin.videoroom"
        obj["session_id"] = sessionId
        if let json = try? JSONSerialization.data(
                withJSONObject: obj,
                options: [.withoutEscapingSlashes]) {
            let obj = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: obj!)
        }
    }

    public func setActiveStatus(bActive: Bool) {
    }

    public func createOffer(handleId: Decimal, sdp: RTCSessionDescription) {
    }

    public func subscriptionStart(subscriptionHandleId: Decimal, roomId: UInt64, sdp: RTCSessionDescription) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "start"
        body["room"] = roomId
        message["janus"] = "message"
        message["body"] = body
        message["transaction"] = randomString(length: 12)
        message["session_id"] = UInt64(sessionId! as NSNumber)
        message["handle_id"] = UInt64(subscriptionHandleId as NSNumber)

        if sdp != nil {
            var jsep: Dictionary<String, Any> = [:]
            switch sdp.type {
            case .offer:
                jsep["type"] = "OFFER"
                break
            case .prAnswer:
                jsep["type"] = "PRANSWER"
                break
            case .answer:
                jsep["type"] = "ANSWER"
                break
            }
            jsep["sdp"] = sdp.description.components(separatedBy: "answer\n")[1]
            message["jsep"] = jsep
        }

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func publish(handleId: Decimal, sdp: RTCSessionDescription) {
        var message: Dictionary<String, Any> = [:]
        var publish: Dictionary<String, Any> = [:]
        publish["request"] = "publish"
        publish["audio"] = true
        publish["video"] = true

        if sdp != nil {
            var jsep: Dictionary<String, Any> = [:]
            switch sdp.type {
            case .offer:
                jsep["type"] = "OFFER"
                break
            case .prAnswer:
                jsep["type"] = "PRANSWER"
                break
            case .answer:
                jsep["type"] = "ANSWER"
                break
            }
            jsep["sdp"] = sdp.description.components(separatedBy: "offer\n")[1]
            message["jsep"] = jsep
        }

        // TODO: unhandled
        message["janus"] = "message"
        message["body"] = publish
        message["transaction"] = randomString(length: 12)
        let formatter = NumberFormatter()
        message["session_id"] = UInt64(sessionId! as NSNumber)
        message["handle_id"] = UInt64(handleId as NSNumber)

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func subscribe(subscriptionHandleId: Decimal, roomId: UInt64, feedId: Decimal) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["ptype"] = "subscriber"
        body["request"] = "join"
        body["room"] = roomId
        body["feed"] = feedId

        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = subscriptionHandleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func trickleCandidate(handleId: Decimal, iceCandidate: RTCIceCandidate) {
        var message: Dictionary<String, Any> = [:]
        var candidate: Dictionary<String, Any> = [:]
        candidate["candidate"] = iceCandidate.sdp
        candidate["sdpMid"] = iceCandidate.sdpMid
        candidate["sdpMLineIndex"] = iceCandidate.sdpMLineIndex
        message["candidate"] = candidate
        message["janus"] = "trickle"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func trickleCandidateComplete(handleId: Decimal) {
        var message: Dictionary<String, Any> = [:]
        var candidate: Dictionary<String, Any> = [:]
        candidate["completed"] = true
        message["candidate"] = candidate
        message["janus"] = "trickle"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func sendMessage(message: String) {
    }

    public func joinRoom(handleId: Decimal, roomId: UInt64, displayName: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["display"] = displayName
        body["ptype"] = "publisher"
        body["request"] = "join"
        body["room"] = roomId
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func createRoom(handleId: Decimal, roomNumber: NSNumber) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        let roomId = roomNumber.uint64Value
        body["request"] = "create"
        if roomNumber != -1 {
            body["room"] = roomId
        }
        body["permanent"] = false

        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func destroyRoom(handleId: Decimal, roomId: UInt64) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "destroy"
        body["room"] = roomId
        body["permanent"] = false
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func requestRoomList(handleId: Decimal) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "list"
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func testToken(handleId: Decimal, token: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "fcm_test"
        body["token"] = token
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func registerToken(handleId: Decimal, token: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "register_token"
        body["token"] = token
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func unregisterToken(handleId: Decimal, token: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "unregister_token"
        body["token"] = token
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func registPeer(handleId: Decimal, name: String, macAddr: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "register"
        body["username"] = name
        body["mac_addr"] = macAddr
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func callPeer(handleId: Decimal, roomNo: UInt64, name: String, bAutoReceive: Bool) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "call"
        body["username"] = name
        body["room"] = roomNo
        body["type"] = bAutoReceive ? "auth" : "normal"
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func acceptCallByFCM(handleId: Decimal, name: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "acceptbytoken"
        body["username"] = name
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func rejectCallByFCM(handleId: Decimal, name: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "rejectbytoken"
        body["username"] = name
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func acceptCall(handleId: Decimal, name: String) {
    }

    public func rejectCall(handleId: Decimal, name: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "reject"
        body["username"] = name
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func hangupPeer(handleId: Decimal) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "hangup"
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
        }
    }

    public func rejectByBusy(handleId: Decimal, name: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "busy"
        body["username"] = name
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
            print("rejectCall:name=\(name) handleId=\(handleId)")
        }
    }

    public func replyCallStandBy(handleId: Decimal, name: String) {
        var message: Dictionary<String, Any> = [:]
        var body: Dictionary<String, Any> = [:]
        body["request"] = "standby"
        body["username"] = name
        message["body"] = body
        message["janus"] = "message"
        message["transaction"] = randomString(length: 12)
        message["session_id"] = sessionId
        message["handle_id"] = handleId

        if let json = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.withoutEscapingSlashes]) {
            let message = String(data: json,
                    encoding: .utf8)
            webSocketChannel?.sendMessage(message: message!)
            print("replyCallStandBy:name=\(name) handleId=\(handleId), message=\(message!)")
        }
    }

    public func onOpen() {
        createSession()
    }

    func convertStringToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }

    public func onMessage(text: String) throws {
//        if let json = try? JSONSerialization.data(
//                withJSONObject: text,
//                options: []) {
        // TODO: 수정요
        if let obj = text.toJSON() as? [String: AnyObject] {
//            let message = String(data: json,
//                    encoding: .utf8)
//            var obj: Dictionary<String, Any> = convertStringToDictionary(text: text)!
            var type: JanusMessageType = JanusMessageType.fromString(string: obj["janus"] as! String)
            var transaction: String? = nil
            var sender: Decimal? = nil
            if let t = obj["transaction"] as? String {
                transaction = t
            }
            if let s = obj["sender"] as? UInt64 {
                sender = Decimal(s)
            }
            var handle: PluginHandle? = nil
            if let sender = sender, let h = attachedPlugins.get(key: "\(sender)") as? PluginHandle {
                handle = h
            }
            // run transaction
            switch type {
            case .keepalive:
                break
            case .ack:
                break
            case .success:
                if let transaction = transaction {
                    if let cb = transactions.get(key: transaction) as? Transaction {
                        print("transaction success: \(transaction)")
                        if let feedId = cb.getFeedId() as? Decimal {
                            print("transaction onSuccess!!! feedId=\(feedId)")
                            try cb.onSuccess(data: obj, feed: feedId)
                        } else {
                            print("transaction onSuccess!!! obj=\(obj)")
                            try cb.onSuccess(data: obj)
                        }
                        // remove transaction
                        transactions.remove(key: transaction)
                    }
                }
                break
            case .error:
                if let transaction {
                    if let cb = transactions.get(key: transaction) as? Transaction {
                        if cb != nil {
                            try cb.onError()
                            transactions.remove(key: transaction)
                        }
                    }
                }
                break
            case .hangup:
                break
            case .detached:
                if handle != nil {
                    if janusCallback != nil {
                        try? janusCallback?.onDetached((handle?.getHandleId())!, reason: nil)
                    }
                }
                break
            case .event:
                if handle != nil {
                    var plugin_data: Dictionary<String, Any>? = nil
                    if let p = obj["plugindata"] as? Dictionary<String, Any> {
                        plugin_data = p
                    }
                    if let plugin_data = plugin_data {
                        var data: Dictionary<String, Any>? = nil
                        var jsep: Dictionary<String, Any>? = nil
                        if let pd = plugin_data["data"] as? Dictionary<String, Any> {
                            data = pd
                        }
                        if let js = obj["jsep"] as? Dictionary<String, Any> {
                            print("jsep received: \(js)")
                            jsep = js
                        }
                        if janusCallback != nil {
                            print("onMessage:handleId=\(handle?.getHandleId())")
                            janusCallback?.onMessage(sender!, (handle?.getHandleId())!, data, jsep)
//                            webSocketChannel?.readMessage()
                        }
                    }
                }
                break
            case .trickle:
                if handle != nil {
                    var candidate: Dictionary<String, Any>? = nil
                    if let c = obj["candidate"] as? Dictionary<String, Any> {
                        candidate = c
                    }
                    if let candidate = candidate {
                        if janusCallback != nil {
                            janusCallback?.onIceCandidate((handle?.getHandleId())!, candidate)
                        }
                    }
                }
                break
            case .destroy:
                if janusCallback != nil {
                    janusCallback?.onDestroySession(sessionId!)
                }
                break
            default:
                break
            }
        }
    }

    public func sendKeepAlive() {
        if webSocketChannel != nil, let connected = webSocketChannel?.isConnected(), connected {
            var obj: Dictionary<String, Any> = [:]
            obj["janus"] = "keepalive"
            obj["session_id"] = sessionId
            obj["transaction"] = randomString(length: 12)
            if webSocketChannel != nil {
                if let json = try? JSONSerialization.data(
                        withJSONObject: obj,
                        options: [.withoutEscapingSlashes]) {
                    let message = String(data: json,
                            encoding: .utf8)
                    webSocketChannel?.sendMessage(message: message!)
                }
            }
        }
    }

    private func startKeepAliveTimer() {
    }

    private func stopKeepAliveTimer() {
        isKeepAliveRunning = Volatile(false)
        if keepAliveThread != nil {
            keepAliveThread?.cancel()
            while let isAlive = keepAliveThread?.isExecuting, isAlive {
                sleep(100)
            }
        }
    }

    public func onClosed(reason: String?) {
        stopKeepAliveTimer()
        if janusCallback != nil {
            janusCallback?.onDetached(Decimal(-1), reason: reason)
        }
    }
}