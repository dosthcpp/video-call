//
// Created by DOYEON BAEK on 2022/10/20.
//

import Foundation

enum WebSocketError: Error {
    case invalidURL
}

@available(iOS 13.0, *)
protocol WebSocketListener {
    func onOpen(webSocket: WebSocket, response: URLResponse)
    func onMessage(webSocket: WebSocket, text: String)
    func onMessage(webSocket: WebSocket, data: Data)
    func onClosing(webSocket: WebSocket, code: Int, reason: String)
    func onClosed(webSocket: WebSocket, code: Int, reason: String)
    func onFailure(webSocket: WebSocket, e: Error, response: URLResponse)
}

@available(iOS 13.0, *)
final class WebSocket: NSObject {
    static let shared = WebSocket()

    private override init() {
    }

    var url: URL?
    var onReceiveClosure: ((String?, Data?) -> ())?
    var listener: WebSocketListener?
    weak var delegate: URLSessionWebSocketDelegate?

    private var webSocketTask: URLSessionWebSocketTask? {
        didSet {
            let reason = "replace"
            oldValue?.cancel(with: .goingAway, reason: Data(reason.utf8))
        }
    }

    private var timer: Timer?

    func newWebSocket() throws {
        guard let url = url else {
            throw WebSocketError.invalidURL
        }

        let urlSession = URLSession(
                configuration: .default,
                delegate: delegate,
                delegateQueue: OperationQueue()
        )
        var request: URLRequest = URLRequest(url: url)

        request.addValue("janus-protocol", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        let webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask.resume()
//        let dataTask = urlSession.dataTask(with: request)
//        dataTask.resume()

        self.webSocketTask = webSocketTask
//        readMessage()
    }

    public func startPing() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(
                withTimeInterval: 10, repeats: true, block: { [weak self] _ in self?.ping() }
        )
    }

    private func ping() {
        webSocketTask?.sendPing(pongReceiveHandler: { [weak self] error in
            guard let error = error else {
                return
            }
            print("Ping failed \(error.localizedDescription)")
            self?.startPing()
        })
    }

    func send(message: String) {
        self.send(message: message, data: nil)
    }

    func send(data: Data) {
        self.send(message: nil, data: data)
    }

    private func send(message: String?, data: Data?) {
        let taskMessage: URLSessionWebSocketTask.Message
        if let string = message {
            taskMessage = URLSessionWebSocketTask.Message.string(string)
        } else if let data = data {
            taskMessage = URLSessionWebSocketTask.Message.data(data)
        } else {
            return
        }

        self.webSocketTask?.send(taskMessage, completionHandler: { [self] error in
            guard let error = error else {
                receive()
                return
            }
            print("WebSocket sending error: \(error)")
        })
    }

    public func receive() {
        self.webSocketTask?.receive(completionHandler: { [self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let onReceiveClosure = onReceiveClosure{
                        onReceiveClosure(text, nil)
                    }
                    if let listener = listener {
                        listener.onMessage(webSocket: self, text: text)
                    }
                case .data(let data):
                    if let onReceiveClosure = onReceiveClosure{
                        onReceiveClosure(nil, data)
                    }
                    if let listener = listener {
                        listener.onMessage(webSocket: self, data: data)
                    }
                @unknown default:
                    fatalError()
                }
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
            }
            receive()
        })
    }

    func closeWebSocket() {
        self.webSocketTask = nil
        self.onReceiveClosure = nil
        self.timer?.invalidate()
        self.delegate = nil
    }
}

// web socket handler
//@available(iOS 13.0, *)
//extension WebSocket: URLSessionWebSocketDelegate {
//    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
//        self.delegate?.urlSession?(
//                session,
//                webSocketTask: webSocketTask,
//                didOpenWithProtocol: `protocol`
//        )
//
//        if let response = webSocketTask.response {
//            self.listener?.onOpen(webSocket: self, response: response)
//        }
//    }
//
//    // get message
//    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didReceiveMessage message: URLSessionWebSocketTask.Message) {
//        print("message: \(message)")
//        switch message {
//        case .string(let text):
//            self.onReceiveClosure?(text, nil)
//            self.listener?.onMessage(webSocket: self, text: text)
//        case .data(let data):
//            self.onReceiveClosure?(nil, data)
//            self.listener?.onMessage(webSocket: self, data: data)
//        @unknown default:
//            fatalError()
//        }
//    }
//
//    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
//        self.delegate?.urlSession?(
//                session,
//                webSocketTask: webSocketTask,
//                didCloseWith: closeCode,
//                reason: reason
//        )
//
//        self.listener?.onClosed(webSocket: self, code: closeCode.rawValue, reason: String(data: reason ?? Data(), encoding: .utf8) ?? "")
//    }
//}