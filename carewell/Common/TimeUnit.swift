//
//  File.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/09/30.
//

import Foundation

enum TimeUnit {
    case NONE
    case EVERYDAY
    case EVERYWEEK
    case EVERYMONTH
    case EVERYYEAR
    case BEFORE_10MINUTES
    case BEFORE_1HOUR
    case BEFORE_1DAY

    func getUnit() -> String {
        switch self {
        case .NONE:
            return "없음"
        case .EVERYDAY:
            return "매일"
        case .EVERYWEEK:
            return "매주"
        case .EVERYMONTH:
            return "매달"
        case .EVERYYEAR:
            return "매년"
        case .BEFORE_10MINUTES:
            return "10분 전"
        case .BEFORE_1HOUR:
            return "1시간 전"
        case .BEFORE_1DAY:
            return "1일 전"
        }
    }
}

enum DayOfWeek {
    case MONDAY
    case TUESDAY
    case WEDNESDAY
    case THURSDAY
    case FRIDAY
    case SATURDAY
    case SUNDAY

    var desc : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .MONDAY: return "월"
        case .TUESDAY: return "화"
        case .WEDNESDAY: return "수"
        case .THURSDAY: return "목"
        case .FRIDAY: return "금"
        case .SATURDAY: return "토"
        case .SUNDAY: return "일"
        }
    }

    var value : Int {
        switch self {
        // Use Internationalization, as appropriate.
        case .SUNDAY: return 1
        case .MONDAY: return 2
        case .TUESDAY: return 3
        case .WEDNESDAY: return 4
        case .THURSDAY: return 5
        case .FRIDAY: return 6
        case .SATURDAY: return 7
        }
    }
}

extension Int {
    var toWeekday: DayOfWeek {
        switch self {
        case 1: return .SUNDAY
        case 2: return .MONDAY
        case 3: return .TUESDAY
        case 4: return .WEDNESDAY
        case 5: return .THURSDAY
        case 6: return .FRIDAY
        case 7: return .SATURDAY
        default: return .MONDAY
        }
    }
}

struct LocalDate {
    var month: Int = 1
    var day: Int = 1

    init(date: Date) {
        self.month = Calendar.current.component(.month, from: date)
        self.day = Calendar.current.component(.day, from: date)
    }

    init(_ month: Int, _ day: Int) {
        self.month = month
        self.day = day
    }
}

extension Date {
    func getDayOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }

    func getYear() -> Int? {
        return Calendar.current.dateComponents([.year], from: self).year
    }

    func getMonth() -> Int? {
        return Calendar.current.dateComponents([.month], from: self).month
    }

    func getDay() -> Int? {
        return Calendar.current.dateComponents([.day], from: self).day
    }

    func getHour() -> Int? {
        return Calendar.current.dateComponents([.hour], from: self).hour
    }

    func getMinute() -> Int? {
        return Calendar.current.dateComponents([.minute], from: self).minute
    }

    func isSameDay(date: Date) -> Bool {
        return self.getDay() == date.getDay() && self.getMonth() == date.getMonth() && self.getYear() == date.getYear()
    }

    func getDateOnly() -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: self))!
    }

    func getTimeOnly() -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.hour, .minute], from: self))!
    }

    func getDateRange() -> DateInterval {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        return DateInterval(start: start, end: end)
    }

    func checkIfDateIsBetween(_ date: Date) -> Bool {
        let dateInterval = getDateRange()
        return dateInterval.contains(date)
    }

    func toTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self)
    }

    func toDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self)
    }

    func toIdString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self)
    }

    func toString() -> String {
        let hour = Calendar.current.dateComponents([.hour], from: self).hour!
        let minute = Calendar.current.dateComponents([.minute], from: self).minute!
        return "\(String(format: "%02d", hour)):\(String(format: "%02d", minute))"
    }

    func toMMDDString() -> String {
        let month = Calendar.current.dateComponents([.month], from: self).month!
        let day = Calendar.current.dateComponents([.day], from: self).day!
        return "\(String(format: "%02d", month))월 \(String(format: "%02d", day))일"
    }

    func toYYYYMMString() -> String {
        let year = Calendar.current.dateComponents([.year], from: self).year!
        let month = Calendar.current.dateComponents([.month], from: self).month!
        return "\(year)년 \(String(format: "%02d", month))월"
    }

    func addOneDay() -> Date? {
        return Calendar.current.date(byAdding: DateComponents(day: 1), to: self)
    }

    func toDateComponent() -> DateComponents? {
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
    }

    static func of(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        return Calendar.current.date(from: dateComponents)!
    }
}

class DayUtil {
    var startDate: Date
    var endDate: Date
    var validDates: [Date] = []

    public init() {
        startDate = Date()
        endDate = Date()
    }

    init(_ startEndDate: DateInterval) {
        startDate = startEndDate.start
        endDate = startEndDate.end
    }

    init(startDate: Date, endDate: Date) {
        let c = Calendar.current
        var sd = startDate.toDateComponent()!
        var ed = endDate.toDateComponent()!
        sd.hour! = 0
        sd.minute! = 0
        sd.second! = 0
        ed.hour! = 23
        ed.minute! = 59
        ed.second! = 59
        self.startDate = c.date(from: sd)!
        self.endDate = c.date(from: ed)!
    }

    func parseUnit(_ unit: String) -> TimeUnit {
        switch unit {
        case "없음":
            return .NONE
        case "매일":
            return .EVERYDAY
        case "매주":
            return .EVERYWEEK
        case "매달":
            return .EVERYMONTH
        case "매년":
            return .EVERYYEAR
        case "10분 전":
            return .BEFORE_10MINUTES
        case "1시간 전":
            return .BEFORE_1HOUR
        case "1일 전":
            return .BEFORE_1DAY
        default:
            return .NONE
        }
    }

    func parseDateArray(_ day: String) -> [DayOfWeek] {
        var ret: [DayOfWeek] = []
        let dayArray = day.components(separatedBy: " ")
        for day in dayArray {
            switch day {
            case "월": ret.append(.MONDAY)
                break
            case "화": ret.append(.TUESDAY)
                break
            case "수": ret.append(.WEDNESDAY)
                break
            case "목": ret.append(.THURSDAY)
                break
            case "금": ret.append(.FRIDAY)
                break
            case "토": ret.append(.SATURDAY)
                break
            case "일": ret.append(.SUNDAY)
                break
            default: break
            }
        }

        return ret
    }

    func parseDayString(_ day: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_kr")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.date(from: day)!
    }

    func parseTimeString(_ time: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_kr")
        formatter.dateFormat = "HH:mm"

        return formatter.date(from: time)!
    }

    func parseDateTimeString(_ dateTime: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_kr")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        return formatter.date(from: dateTime)!
    }

    // schedule

    private func add(_ date: Date, _ t: TimeUnit) -> Date {
        if t == .EVERYDAY {
            print(date.addOneDay()!)
            return date.addOneDay()!
        } else if t == .EVERYWEEK {
            // add a week to date
            return Calendar.current.date(byAdding: DateComponents(day: 7), to: date)!
        } else if t == .EVERYMONTH {
            // add a month to date
            return Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        } else if t == .EVERYYEAR {
            // add a year to date
            return Calendar.current.date(byAdding: DateComponents(year: 1), to: date)!
        } else {
            return Date()
        }
    }

    public func getDayOfWeekArrayList(_ t: TimeUnit) -> [DayOfWeek] {
        var ret: [DayOfWeek] = []
        var date = startDate
//        if Date() > date {
//            date = add(date, t)
//        }
        while date <= endDate {
            ret.append(date.getDayOfWeek()!.toWeekday)
            date = add(date, t)
        }
        return ret
    }

    public func getValidDates(_ t: TimeUnit) -> [Date] {
        var ret: [Date] = []
        var date = startDate
        let dayOfWeekArrayList = getDayOfWeekArrayList(t)
        while date <= endDate {
            if dayOfWeekArrayList.contains(date.getDayOfWeek()!.toWeekday) {
                ret.append(date)
            }
            date = date.addOneDay()!
        }

        print(ret)

        return ret
    }

    // pill
    private func checkValid(_ start: Date, _ dayOfWeeks: [DayOfWeek]) -> Bool {
        var d = start

        while(d <= endDate) {
            var i = 0
            for _ in 0...dayOfWeeks.count - 1 {
                if(d.getDayOfWeek() == dayOfWeeks[i].value) { break }
                i += 1
            }
            if(i < dayOfWeeks.count) {
                return true
            }
            d = d.addOneDay()!
        }
        return false
    }

    public func isValidDate(calendar: Date, dayOfWeeks: [DayOfWeek]) -> Bool {
        let date = calendar

        let isBetweenTwoDates = date >= startDate && date <= endDate
        if(!isBetweenTwoDates || dayOfWeeks.count == 0) {
            return false
        }

        if(date > Date()) {
            return checkValid(date, dayOfWeeks)
        } else {
            return checkValid(date.addOneDay()!, dayOfWeeks)
        }
    }

    private func add(_ start: Date, _ dayOfWeeks: [DayOfWeek]) {
        var d = start

        while(d <= endDate) {
            var i = 0
            for _ in 0...dayOfWeeks.count - 1 {
                if(d.getDayOfWeek() == dayOfWeeks[i].value) {
                    validDates.append(d)
                }
                i += 1
            }
            d = d.addOneDay()!
        }
    }

    public func get(calendar: Date, dayOfWeeks: [DayOfWeek]) {
        let date = calendar

        let isBetweenTwoDates = date >= startDate && date <= endDate
        if(!isBetweenTwoDates || dayOfWeeks.count == 0) {
            return
        }

        add(date, dayOfWeeks)
    }

    public func getLatestValidDate() -> Date {
        if validDates.count == 0 {
            return Date()
        }
        return validDates[validDates.count - 1]
    }
}
