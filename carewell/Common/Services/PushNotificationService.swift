//
//  PushNotificationService.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/02.
//

import Foundation
import UserNotifications

class PushNotificationService {
    public static func registerOrModifyPillAlert(_ p: AlarmModel, _ modify: Bool) {
        let dayArray: [DayOfWeek] = p.getDayArray()
        var week: [Bool] = [Bool](repeating: false, count: 8)

        if (dayArray.count > 0) {
            for i in 0...dayArray.count - 1 {
                week[dayArray[i].value] = true
            }
        }

        var pillCalendar = p.getPillCalendar()!

        let dayUtil = DayUtil(startDate: p.getAlertDateRange()!.start, endDate: p.getAlertDateRange()!.end)

        let notiCenter = UNUserNotificationCenter.current()

        while (dayUtil.isValidDate(calendar: pillCalendar, dayOfWeeks: dayArray)) {

            let dayOfWeek = pillCalendar.getDayOfWeek()!
            let now = Date()

            if now < pillCalendar && week[dayOfWeek] {
                let date = pillCalendar.addingTimeInterval(0).toDateComponent()!
                let id = "pill \(Calendar.current.date(from: date)!.toIdString()) \(p.getId()!)"

                notiCenter.getNotificationSettings(completionHandler: { settings in
                    if settings.authorizationStatus == UNAuthorizationStatus.authorized {
                        let nContents = UNMutableNotificationContent()
                        nContents.badge = 1
                        nContents.title = p.getTitle()!
                        nContents.subtitle = "서브타이틀"
                        nContents.body = "알람"
                        nContents.sound = UNNotificationSound.default
                        nContents.userInfo = ["name": "Infomark"]

                        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
//                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                        let request = UNNotificationRequest(identifier: id, content: nContents, trigger: trigger)
                        // cancel alarm
                        if modify {
                            // remove old alarm
                            notiCenter.removePendingNotificationRequests(withIdentifiers: [id])
                        }
                        // register alarm
                        // 가장 최근거만..
                        notiCenter.add(request) { error in
                            if let error = error {
                                print(error)
                            }
                        }
                    }
                })

                #if DEBUG
                let _now = now.toDateComponent()!
                print("등록 버튼을 누른 시간 : \(_now), 설정한 시간 : \(date) with id: \(id)")
                let util = CommonUtil()
                let currentDateTime = pillCalendar
                let date_text = util.toDateString(date: currentDateTime)
                util.showToast("등록된 알림 시간 : \(date_text)")
                #endif
            }

            pillCalendar = pillCalendar.addOneDay()!
        }
    }

    public static func registerOrModifySchedule(_ event: ScheduleEvent, _ date: Date, _ modify: Bool) {
        var _date = date
        let when = event.getWhen()

        switch when {
        case .BEFORE_10MINUTES:
            _date = _date.addingTimeInterval(-10 * 60)
            break
        case .BEFORE_1HOUR:
            _date = _date.addingTimeInterval(-60 * 60)
            break
        case .BEFORE_1DAY:
            _date = _date.addingTimeInterval(-24 * 60 * 60)
            break
        case .NONE:
            break
        default:
            break
        }

        if Date() < _date {
            let id = "schedule \(_date.toIdString()) \(event.getId())"

            let notiCenter = UNUserNotificationCenter.current()

            notiCenter.getNotificationSettings(completionHandler: { settings in
                if settings.authorizationStatus == UNAuthorizationStatus.authorized {
                    let nContents = UNMutableNotificationContent()
                    nContents.badge = 1
                    nContents.title = event.getTitle()
                    nContents.subtitle = "서브타이틀"
                    nContents.body = "알람"
                    nContents.sound = UNNotificationSound.default
                    nContents.userInfo = ["name": "Infomark"]

                    let trigger = UNCalendarNotificationTrigger(dateMatching: _date.toDateComponent()!, repeats: false)
                    let request = UNNotificationRequest(identifier: id, content: nContents, trigger: trigger)
                    if modify {
                        // remove old alarm
                        notiCenter.removePendingNotificationRequests(withIdentifiers: [id])
                    }

                    notiCenter.add(request) { error in
                        if let error = error {
                            print(error)
                        }
                    }
                }
            })

            #if DEBUG
            let _now = Date().toDateComponent()!
            print("등록 버튼을 누른 시간 : \(_now), 설정한 시간 : \(_date.toDateComponent()!) with id: \(id)")
            let util = CommonUtil()
            let currentDateTime = _date
            let date_text = util.toDateString(date: currentDateTime)
            util.showToast("등록된 알림 시간 : \(date_text)")
            #endif
        } else {
            print("일정이 등록되지 않았습니다.")
        }
    }
}
