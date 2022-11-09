//
//  Consts.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/09/30.
//

import Foundation


class Consts {
    #if DEBUG
    static var baseUrl: String = "https://api-test.carewellplus.co.kr"
    #else
    static var baseUrl: String = "https://api.carewellplus.co.kr"
    #endif

    let notificationKey = "kr.co.carewell.notificationKey"
    let ACTION_RESTART_MONITOR_ALIVE = "ACTION.RESTART.KEEP_ALIVE";
    
    public static func getBaseUrl() -> String {
        return baseUrl
    }
}
