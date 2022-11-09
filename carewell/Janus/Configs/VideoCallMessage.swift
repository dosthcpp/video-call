//
// Created by DOYEON BAEK on 2022/10/23.
//

import Foundation

public class VideoCallMessage {

    // 내부 신호 처리용.

    public static var Action_VideoCall_Close: String = "LOCAL_VIDEOCALL.CLOSE";

    public static var Action_VideoCall_Regist: String = "LOCAL_VIDEOCALL.REGIST";
    public static var Action_VideoCall_Incomming: String = "LOCAL_VIDEOCALL.INCOMMING";

    public static var Action_Start_VideoCall_Ind: String = "LOCAL_VIDEOCALL.CALL.START.IND"; // 영상통화를 실행 할 때 외부에서 알리는 신호.
    public static var Action_Stop_VideoCall_Ind: String = "LOCAL_VIDEOCALL.CALL.STOP.IND"; // 영상통화를 종료할 때 외부에 알리는 신호.

    public static var Action_Start_Call: String = "LOCAL_VIDEOCALL.START_CALL";

}
