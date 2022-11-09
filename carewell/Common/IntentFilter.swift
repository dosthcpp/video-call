//
// Created by DOYEON BAEK on 2022/10/23.
//

import Foundation

//implemented by the class that wants to receive the intent

protocol IntentFilter {
    var id: String { get }
    var action: [String] { get }
    func onReceive(intent: Intent)
    func getAction() -> [String]
}

//intent class

class Intent {
    var action: String
    var data: [String: Any]

    init(action: String, data: [String: Any]) {
        self.action = action
        self.data = data
    }

    func getAction() -> String {
        return action
    }

    func getData() -> [String: Any] {
        return data
    }
}

//intent manager class

class IntentManager {
    static let shared = IntentManager()

    private var intentFilters: [IntentFilter] = []

    func registerIntentFilter(intentFilter: IntentFilter) {
        intentFilters.append(intentFilter)
    }

    func unregisterIntentFilter(intentFilter: IntentFilter) {
        intentFilters.removeAll {
            if let id = $0.id as? String {
                return id == intentFilter.id
            }
        }
    }

    func sendIntent(intent: Intent) {
        for intentFilter in intentFilters {
            intentFilter.onReceive(intent: intent)
        }
    }
}

//usage

//class ViewController: UIViewController, IntentFilter {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        IntentManager.shared.registerIntentFilter(intentFilter: self)
//    }
//
//    func onReceiveIntent(intent: Intent) {
//        if intent.action == "action" {
//            //do something
//        }
//    }
//}