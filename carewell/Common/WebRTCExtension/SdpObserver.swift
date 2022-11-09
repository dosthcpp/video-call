//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

protocol SdpObserver {
    func onCreateSuccess(var1: String)
    func onCreateFailure(var1: String)
    func onSetSuccess()
    func onSetFailure(var1: String)
}
