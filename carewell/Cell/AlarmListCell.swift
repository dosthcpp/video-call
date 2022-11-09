//
//  AlarmListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/06/07.
//

import UIKit

class AlarmModel: Equatable {
    static func == (l: AlarmModel, r: AlarmModel) -> Bool {
        l.id == r.id
    }
    
    private var id: String?
    private var isEnabled: Bool = false
    private var title: String?
    private var pillCalendar: Date?
    private var alertDateRange: DateInterval?
    private var dayArray: [DayOfWeek]
    private var validDates: [Date] = []
    private var context: AlarmListViewController?
    private var dayUtil: DayUtil?

    public func setDayUtil(dayUtil: DayUtil) {
        self.dayUtil = dayUtil
    }

    public func setId(id: String) {
        self.id = id
    }

    public func getId() -> String? {
        return id
    }

    public func setTitle(title: String) {
        self.title = title
    }

    public func getTitle() -> String? {
        return title
    }

    public func setPillCalendar(pillCalendar: Date) {
        self.pillCalendar = pillCalendar
    }

    public func getPillCalendar() -> Date? {
        return pillCalendar
    }

    public func setDisabled() { isEnabled = false }

    public func setEnabled() {
        isEnabled = true
    }

    public func checkEnabled() -> Bool? {
        return isEnabled
    }

    public func toggleEnabled() {
        isEnabled = !isEnabled
    }

    public func setDays(pill_period: [DayOfWeek]) {
        self.dayArray = pill_period
    }

    public func getDayArray() -> [DayOfWeek] {
        return dayArray
    }

    public func setDayArray(pill_period: [DayOfWeek]) {
        self.dayArray = pill_period
    }

    public func getAlertDateRange() -> DateInterval? {
        return alertDateRange
    }

    public func setAlertDateRange(alertDateRange: DateInterval) {
        self.alertDateRange = alertDateRange
    }

    public func getDayUtil() -> DayUtil? {
        return dayUtil
    }
    
    public func getContext() -> AlarmListViewController? {
        return context
    }

    public func appendDate(date: Date) {
        validDates.append(date)
    }

    public func getTheLatestValidDate() -> Date? {
        dayUtil?.get(calendar: pillCalendar!, dayOfWeeks: dayArray)
        let dates = dayUtil!.getLatestValidDate()
        return dates
    }

    public init(_ id: String? = "111", _ title: String = "복약알림", _ pillCalendar: Date = Date(), _ alertDateRange: DateInterval = DateInterval(), _ dayArray: [DayOfWeek] = [], _ context: AlarmListViewController = AlarmListViewController()) {
        self.id = id
        self.title = title
        self.pillCalendar = pillCalendar
        self.alertDateRange = alertDateRange
        self.dayArray = dayArray
        self.context = context
        dayUtil = DayUtil(startDate: alertDateRange.start, endDate: alertDateRange.end)

        let now = Date()
        var d = alertDateRange.end.toDateComponent()!
        d.hour! = 23
        d.minute! = 59
        d.second! = 59
        dayUtil?.get(calendar: pillCalendar, dayOfWeeks: dayArray)

        let isAlertAvailable = now < (dayUtil?.getLatestValidDate())! && pillCalendar <= Calendar.current.date(from: d)!
        isEnabled = isAlertAvailable
    }
}

class AlarmListCell: UITableViewCell {
    @IBOutlet var border: UIView!
    @IBOutlet var border2: UIView!

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var periodLabel: UILabel!

    public var time: String {
        get {
            timeLabel.text!
        }
        set {
            timeLabel.text = newValue
        }
    }
    public var name: String {
        get {
            nameLabel.text!
        }
        set {
            nameLabel.text = newValue
        }
    }
    public var period: String {
        get {
            periodLabel.text!
        }
        set {
            periodLabel.text = newValue
        }
    }
    private var _model: AlarmModel = AlarmModel()
    public var model: AlarmModel {
        get { _model }
        set {
            _model = newValue
            var days_of_weeks = ""
            for (idx, p) in _model.getDayArray().enumerated() {
                days_of_weeks += p.desc
                if idx != _model.getDayArray().endIndex - 1 {
                    days_of_weeks += " "
                }
            }
            time = _model.getPillCalendar()!.toString()
            name = _model.getTitle()!
            period = days_of_weeks
            let today = Date()
            // let delay: Double = alertDateRange.end.timeIntervalSince(today)

            if(_model.checkEnabled()!) {
                border.borderColor = UIColor(rgb: 0xf03e00)
                border2.backgroundColor = UIColor(rgb: 0xf03e00)
                let delay = Calendar.current.date(bySettingHour: _model.getPillCalendar()!.getHour()!, minute: _model.getPillCalendar()!.getMinute()!, second: 0, of: _model.getAlertDateRange()!.end)?.timeIntervalSince(today)
                Timer.scheduledTimer(withTimeInterval: delay!, repeats: false, block: { [self] timer in
                    moveToDisabledField()
                })
            } else {
                border.borderColor = UIColor(rgb: 0xE3E3E3)
                border2.backgroundColor = UIColor(rgb: 0xE3E3E3)
                moveToDisabledField()
            }
        }
    }

    private func moveToDisabledField() {
        let context = _model.getContext()!
        if let index = context.currentModelList.firstIndex(of: _model) {
            context.currentModelList.remove(at: index)
            context.currentTableView.reloadData()
            _model.setDisabled()
            context.preModelList.append(_model)
            context.preTableView.reloadData()
        }
    }
}
