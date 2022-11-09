//
//  Constant.swift
//  carewell
//
//  Created by 유영문 on 2022/05/25.
//

import Foundation


//MARK: - UIButton naming
enum ViewTag: Int {
    case login_button                       =   100000
    case login_search_button                =   100001
    case login_join_button                  =   100002
    
    case agree_all_button                   =   100003
    case agree_service_button               =   100004
    case agree_private_button               =   100005
    case agree_service_detail_button        =   100006
    case agree_private_detail_button        =   100007
    case agree_confirm_button               =   100008
    
    case join_back_button                   =   100009
    case join_next_button                   =   100010
    
    case search_back_button                 =   100011
    case search_tab1_button                 =   100012
    case search_tab2_button                 =   100013
    
    case result_id_back_button              =   100014
    case result_id_login_button             =   100015
    case result_id_reset_pw_button          =   100016
    
    case header_notice_button               =   100017
    case header_setting_button              =   100018
    
    case setting_back_button                =   100020
    case setting_modify_pw_button           =   100021
    case setting_client_center_button       =   100022
    case setting_terms_button               =   100023
    
    case modify_pw_back_button              =   100024
    case modify_pw_confirm_button           =   100025
    
    case terms_back_button                  =   100026
    case terms_coop_info_button             =   100027
    case terms_service_button               =   100028
    case terms_privacy_button               =   100029
    
    case notice_back_button                 =   100030
    case notice_tab1_button                 =   100031
    case notice_tab2_button                 =   100032
    
    case album_list_setting_button          =   100033
    case album_list_send_button             =   100034
    
    case call_list_add_button               =   100035
    
    case call_start_back_button             =   100036
    case call_start_call_button             =   100037
    
    case call_connect_cancel_button         =   100038
    case call_connect_exit_button           =   100039
    case call_connect_retry_button          =   100040
    
    case call_add_cancel_button             =   100041
    case call_add_delete_button             =   100042
    case call_add_time_button               =   100043
    case call_add_person_button             =   100044
    case call_add_confirm_button            =   100045
    
    case time_setting_cancel_button         =   100046
    case time_setting_minute_button         =   30
    case time_setting_one_hour_button       =   1
    case time_setting_two_hour_button       =   2
    case time_setting_confirm_button        =   100050
    
    case join_setting_cancel_button         =   100051
    case join_setting_search_button         =   100052
    case join_setting_confirm_button        =   100053
    
    case alarm_list_add_button              =   100054
    
    case alarm_setting_cancel_button        =   100055
    case alarm_setting_delete_button        =   100056
    case alarm_setting_everyday_button      =   100057
    case alarm_setting_confirm_button       =   100058
    
    case schedule_list_add_button           =   100059
    
    case schedule_setting_cancel_button     =   100060
    case schedule_setting_delete_button     =   100061
    case schedule_setting_start_button      =   100062
    case schedule_setting_end_button        =   100063
    case schedule_setting_confirm_button    =   100064
}

//MARK: - Key String
public let DELEGATE: String = "delegate"
public let TITLE: String = "title"
public let DATA: String = "data"

public let MONTH_ARRAY: Array<String> = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
public let DAY_ARRAY: Array<String> = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10",
                                       "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
                                       "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"]
public let AM_PM_ARRAY: Array<String> = ["오전", "오후"]
public let HOUR_ARRAY: Array<String> = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
public let MINUTE_ARRAY: Array<String> = ["00", "05", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55"]


//MARK: - Enumerations
enum PopupType {
    case CLOSE
    case COMPLETE
}

