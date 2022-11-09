//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

protocol IVideoCallServiceCallback {
    var id: String { get }
    func onDataChangedInd(what_data: String)
    func onStatusInd(status: String, statusCode: Int)
    func onMessageReceived(msg_type: String, msg: String, sdata: String, fdata: Float, idata: Int, bdata: Bool, from: String)
}

extension IVideoCallServiceCallback {
    static func ==(lhs: IVideoCallServiceCallback, rhs: IVideoCallServiceCallback) -> Bool {
        return lhs.id == rhs.id
    }
}