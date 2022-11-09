//
// Created by DOYEON BAEK on 2022/10/20.
//

import Foundation

@available(iOS 13.0, *)
public protocol WebSocketCallback {
    func onOpen()
    func onMessage(text: String) throws
    func onClosed(reason: String?)
}

@available(iOS 13.0, *)
public class WebSocketChannel: NSObject {
    private var webSocket: WebSocket?
    private var connected: Bool
    private var webSocketCallback: WebSocketCallback?

    public override init() {
        connected = false
    }

    public func connect(url: String) {
        webSocket = WebSocket.shared
        WebSocket.shared.url = URL(string: url)
        WebSocket.shared.delegate = self
        WebSocket.shared.listener = WebSocketHandler(channel: self)
        WebSocket.shared.onReceiveClosure = { (string, data) in
//            print(string, data)
        }
        try? WebSocket.shared.newWebSocket()
    }

    public func isConnected() -> Bool {
        connected
    }

    public func setConnected(connected: Bool) {
        self.connected = connected
    }

    public func sendMessage(message: String) {
        if let webSocket = webSocket {
            if connected {
                print("send==>>\(message)")
                webSocket.send(message: message)
            } else {
                print("send failed socket not connected:\(String(describing: webSocket)), connected:\(connected)")
            }
        }
    }

    public func close() {
        if let webSocket = webSocket {
            webSocket.closeWebSocket()
            self.webSocket = nil
        }
    }

    private class WebSocketHandler: WebSocketListener {
        public init(channel: WebSocketChannel) {
            self.channel = channel
        }

        let channel: WebSocketChannel?

        func onOpen(webSocket: WebSocket, response: URLResponse) {
            print("on open websocket")
            channel?.connected = true
            if let webSocketCallback = channel?.webSocketCallback {
                webSocketCallback.onOpen()
            }
        }

        func onMessage(webSocket: WebSocket, text: String) {
            print("onMessage==>>\(text)")
            if let webSocketCallback = channel?.webSocketCallback {
                try? webSocketCallback.onMessage(text: text)
            }
        }

        func onMessage(webSocket: WebSocket, data: Data) {
            print("onMessage==>>\(data)")
        }

        func onClosing(webSocket: WebSocket, code: Int, reason: String) {
            print("onClosing")
        }

        func onClosed(webSocket: WebSocket, code: Int, reason: String) {
            channel?.connected = false
            print("websocket onClosed")
            if let webSocketCallback = channel?.webSocketCallback {
                webSocketCallback.onClosed(reason: reason)
            }
        }

        func onFailure(webSocket: WebSocket, e: Error, response: URLResponse) {
            print("onFailure \(e.localizedDescription)")
            channel?.connected = false;
            if let webSocketCallback = channel?.webSocketCallback {
                webSocketCallback.onClosed(reason: nil)
            }
        }

    }

    public func setWebSocketCallback(webSocketCallback: WebSocketCallback) {
        self.webSocketCallback = webSocketCallback
    }
}

// web socket handler
@available(iOS 13.0, *)
extension WebSocketChannel: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("onOpen")
        connected = true
        webSocketCallback?.onOpen()
        WebSocket.shared.startPing()
//        WebSocket.shared.receive()
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // reason data to string
        let reasonString = String(data: reason ?? Data(), encoding: .utf8)
        print("onClosed, closeCode: \(closeCode) reason: \(reasonString)")
        connected = false
        webSocketCallback?.onClosed(reason: reasonString)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError: onClosed")
        connected = false
        webSocketCallback?.onClosed(reason: nil)
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError: onClosed")
        connected = false
        webSocketCallback?.onClosed(reason: nil)
    }

//    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didReceive message: URLSessionWebSocketTask.Message) {
//        print("onMessage")
//        switch message {
//        case .string(let text):
//            // not working
//            print("onMessage " + text);
//            try? webSocketCallback?.onMessage(text: text)
//        case .data(let data):
//            print("data: \(data)")
//        @unknown default:
//            print("unknown")
//        }
//    }
}