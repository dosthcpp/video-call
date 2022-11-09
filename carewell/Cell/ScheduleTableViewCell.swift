//
//  ScheduleTableViewCell.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/10.
//

import UIKit

class ScheduleEvent: Equatable {
    static func == (l: ScheduleEvent, r: ScheduleEvent) -> Bool {
        l.id == r.id
    }

    private var id: String
    private var enabled: Bool
    private var isMount: Bool
    private var title: String
    private var startEndTime: DateInterval
    private var repeatOption: TimeUnit
    private var when: TimeUnit

    init(_ title: String, _ startEndTime: DateInterval, _ repeatOption: TimeUnit, _ when: TimeUnit) {
        id = CommonUtil().generateRandom(length: 10)
        self.startEndTime = startEndTime
        self.title = title
        if startEndTime.end < Date() {
            enabled = false
        } else {
            enabled = true
        }
        isMount = false
        self.repeatOption = repeatOption
        self.when = when
    }

    init() {
        id = CommonUtil().generateRandom(length: 10)
        startEndTime = DateInterval()
        title = ""
        enabled = false
        isMount = false
        repeatOption = .NONE
        when = .NONE
    }

    func clone() -> ScheduleEvent {
        let clone = ScheduleEvent()
        clone.id = id
        clone.startEndTime = startEndTime
        clone.title = title
        clone.enabled = enabled
        clone.isMount = isMount
        clone.repeatOption = repeatOption
        clone.when = when
        return clone
    }

    public func remove(index: Int) {
        enabled = false
        isMount = false
        id = ""
        startEndTime = DateInterval()
        title = ""
    }

    public func getRepeatOption() -> TimeUnit {
        return repeatOption
    }

    public func getWhen() -> TimeUnit {
        return when
    }

    public func setRepeatOption(_ repeatOption: TimeUnit) {
        self.repeatOption = repeatOption
    }

    public func setWhen(_ when: TimeUnit) {
        self.when = when
    }

    public func getId() -> String {
        id
    }

    public func isEnabled() -> Bool {
        enabled
    }

    public func getMount() -> Bool {
        isMount
    }

    public func getTitle() -> String {
        title
    }

    public func getStartEndTime() -> DateInterval {
        startEndTime
    }

    public func setId(_ id: String) {
        self.id = id
    }

    public func setEnabled() {
        self.enabled = true
    }

    public func setDisabled() {
        self.enabled = false
    }

    public func setMount() {
        self.isMount = true
    }

    public func setUnmount() {
        self.isMount = false
    }

    public func setTitle(_ title: String) {
        self.title = title
    }

    public func setStartEndTimes(_ startEndTime: DateInterval) {
        self.startEndTime = startEndTime
    }

    func toString() -> String {
        return "id: \(id), enabled: \(enabled), isMount: \(isMount), title: \(title), startEndTime: \(startEndTime), repeatOption: \(repeatOption), when: \(when)"
    }
}

class ScheduleTableViewCell: UITableViewCell {
    @IBOutlet var scheduleStatus: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var timeRange: UILabel!

    private var _model: ScheduleEvent = ScheduleEvent()
    public var model: ScheduleEvent {
        get { _model }
        set {
            _model = newValue

            let circle = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
            // set the circle's color
            circle.backgroundColor = _model.isEnabled() ? .red : .gray
            // set the circle's corner radius
            circle.layer.cornerRadius = circle.frame.width / 2
            // center the circle
            circle.center = scheduleStatus.convert(scheduleStatus.center, from: scheduleStatus.superview)
            // disable cell selection
            selectionStyle = .none
            // add the circle to the cell
            scheduleStatus.addSubview(circle)
            scheduleStatus.backgroundColor = .clear
            title.text = _model.getTitle()
            title.sizeToFit()

            // 배경색 투명
            backgroundColor = .clear

            // from start time to end time
            let startTime = _model.getStartEndTime().start
            let endTime = _model.getStartEndTime().end
            timeRange.text = "\(startTime.getHour()!.zeroPadding()):\(startTime.getMinute()!.zeroPadding())~\(endTime.getHour()!.zeroPadding()):\(endTime.getMinute()!.zeroPadding())"
        }
    }
}
