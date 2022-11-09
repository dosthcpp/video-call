//
// Created by DOYEON BAEK on 2022/10/23.
//

import Foundation

protocol IVdeoCallService {
    func registerCallback(cb: IVideoCallServiceCallback)
    func unregisterCallback(cb: IVideoCallServiceCallback)
    func setReceiveModeVisualTalk(bReceiveMode: Bool)
    func getReceiveModeVisualTalk()
    func registerUser(userName: String)
    func callPeer(calleName: String)
    func hangupPeer()
    func trickleCandidateComplete()
    func trickleCandidate(candidate: String)
    func connectToPeer(callerName: String)
    func sendMessageToTarget(msg_type: String, msg: String, sdata: String, fdata: Float, idata: Int, bdata: Bool, targetIpAddress: String)
}