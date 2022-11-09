//
// Created by DOYEON BAEK on 2022/10/26.
//

import Foundation

class BroadcastReceiver {
    private var handler = NotificationCenter.default
    private var intentFilter: IntentFilter?
    public var intent: Intent?
    private var registered = false

    init() {
    }

    func registerIntentFilter(intentFilter: IntentFilter) {
        self.intentFilter = intentFilter
        self.registered = true
    }

    func unregisterIntentFilter() {
        self.intentFilter = nil
        self.registered = false
    }

    func sendIntent(intent: Intent) {
        self.intent = intent
        if self.registered {
            self.handler.post(name: NSNotification.Name(rawValue: intent.action), object: nil)
        }
    }

    func onReceive(handler: @escaping (Intent) -> Void) {
        if let intentFilter = self.intentFilter {
            for action in intentFilter.getAction() {
                self.handler.addObserver(forName: NSNotification.Name(rawValue: action), object: nil, queue: nil) { _ in
                    if let intent = self.intent {
                        handler(intent)
                    }
                }
            }
        }
    }

//    func onReceive(handler: @escaping (Intent) -> Void, action: String) {
//        self.handler.addObserver(forName: NSNotification.Name(rawValue: action), object: nil, queue: nil) { _ in
//            if let intent = self.intent {
//                handler(intent)
//            }
//        }
//    }
//
//    func onReceive(handler: @escaping (Intent) -> Void, actions: [String]) {
//        for action in actions {
//            self.handler.addObserver(forName: NSNotification.Name(rawValue: action), object: nil, queue: nil) { _ in
//                if let intent = self.intent {
//                    handler(intent)
//                }
//            }
//        }
//    }
//
//    func onReceive(handler: @escaping (Intent) -> Void, actions: String...) {
//        for action in actions {
//            self.handler.addObserver(forName: NSNotification.Name(rawValue: action), object: nil, queue: nil) { _ in
//                if let intent = self.intent {
//                    handler(intent)
//                }
//            }
//        }
//    }
//
//    func onReceive(handler: @escaping (Intent) -> Void, actions: [String], intentFilter: IntentFilter) {
//        for action in actions {
//            self.handler.addObserver(forName: NSNotification.Name(rawValue: action), object: nil, queue: nil) { _ in
//                if let intent = self.intent {
//                    if intentFilter.getAction().contains(intent.action) {
//                        handler(intent)
//                    }
//                }
//            }
//        }
//    }

    func unregisterReceiver() {
        if !registered {
            return
        }
        handler.removeObserver(self)
        registered = false
    }
}