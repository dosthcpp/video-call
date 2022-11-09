//
//  ScheduleListViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit
import FSCalendar

class ScheduleListViewController: BaseViewController, ScheduleListener {

    func addSchedule(_ schedule: ScheduleEvent, _ upload: Bool, _ willSelect: Bool) {
        let dayUtil = DayUtil(schedule.getStartEndTime())
        let validDates: [Date] = dayUtil.getValidDates(schedule.getRepeatOption())

        for validDate in validDates {
            let _schedule = schedule.clone()
            let startTime = Date.of(year: validDate.getYear()!, month: validDate.getMonth()!, day: validDate.getDay()!, hour: _schedule.getStartEndTime().start.getHour()!, minute: _schedule.getStartEndTime().start.getMinute()!)
            let endTime = Date.of(year: validDate.getYear()!, month: validDate.getMonth()!, day: validDate.getDay()!, hour: _schedule.getStartEndTime().end.getHour()!, minute: _schedule.getStartEndTime().end.getMinute()!)
            let dateInterval = DateInterval(start: startTime, end: endTime)
            _schedule.setStartEndTimes(dateInterval)
            if validDate.getDateOnly() < Date().getDateOnly() || (validDate.getDateOnly() == Date().getDateOnly() && _schedule.getStartEndTime().end.getTimeOnly() < Date().getTimeOnly()) {
                _schedule.setDisabled()
            } else {
                _schedule.setEnabled()
            }
            let count = scheduleList[validDate.getDateOnly()]?.count ?? 0
            let key = validDate.getDateOnly()
            if scheduleList[key] == nil {
                scheduleList[key] = [_schedule]
            } else if count < 4 {
                scheduleList[key]?.append(_schedule)
            }

            // upload to server
            if upload, count < 4 {
                let param: [String: Any] = [
                    "schedule_id": CommonUtil().generateRandom(length: 10),
                    "guardian_id": Global.shared.getPhoneNumber(),
                    "title": schedule.getTitle(),
                    "date": validDate.toDateString(),
                    "start_time": schedule.getStartEndTime().start.toTimeString(),
                    "end_time": schedule.getStartEndTime().end.toTimeString(),
                    "when": schedule.getWhen().getUnit(),
                    "repeat": schedule.getRepeatOption().getUnit()
                ] as Dictionary //JSON 객체로 전송할 딕셔너리
                let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/add_schedule_new2")!
                InfomarkClient().post(param: param, url: url, runnable: { obj in
                    let jsonObject = obj as! NSDictionary
                    _ = jsonObject["state"] as? String
                    _ = jsonObject["error"] as? String

                    print("upload success!!")
                })
            }

            PushNotificationService.registerOrModifySchedule(_schedule, validDate, false)
        }

        selectedDate = schedule.getStartEndTime().start
        if willSelect {
            select(selectedDate)
        }
        calendarView.reloadData()
    }

    func modifySchedule(_ schedule: ScheduleEvent, _ index: Int, _ upload: Bool) {
        scheduleList[selectedDate.getDateOnly()]?[index] = schedule.clone()
        // 날짜가 달라지면 그 날짜로 옮겨야함
        if upload {
            let param: [String: Any] = [
                "schedule_id": schedule.getId(),
                "guardian_id": Global.shared.getPhoneNumber(),
                "title": schedule.getTitle(),
                "start_time": schedule.getStartEndTime().start.toTimeString(),
                "end_time": schedule.getStartEndTime().end.toTimeString(),
                "when": schedule.getWhen().getUnit()
            ] as Dictionary //JSON 객체로 전송할 딕셔너리
            let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/modify_schedule")!
            InfomarkClient().post(param: param, url: url, runnable: { obj in
                let jsonObject = obj as! NSDictionary
                _ = jsonObject["state"] as? String
                _ = jsonObject["error"] as? String

                print("upload success!!")
            })
        }
        calendarView.reloadData()
        tableView.reloadData()
    }

    func deleteSchedule(_ index: Int) {
        let schedule = scheduleList[selectedDate.getDateOnly()]![index]
        // delete from scheduleList
        scheduleList[selectedDate.getDateOnly()]?.remove(at: index)
        print("schdule id: \(schedule.getId())")
        // delete from server
        let param: [String: Any] = [
            "schedule_id": schedule.getId(),
            "guardian_id": Global.shared.getPhoneNumber()
        ] as Dictionary //JSON 객체로 전송할 딕셔너리
        let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/delete_schedule")!
        InfomarkClient().post(param: param, url: url, runnable: { obj in
            let jsonObject = obj as! NSDictionary
            _ = jsonObject["state"] as? String
            _ = jsonObject["error"] as? String

            print("delete success!!")
        })
        calendarView.reloadData()
        tableView.reloadData()
    }

    @IBOutlet var calendarView: FSCalendar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var selectedDateLabel: UILabel!

    @IBOutlet var currentDate: UILabel!
    @IBOutlet var prevBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!

    var selectedDate: Date = Date()
    private lazy var today: Date = {
        Date()
    }()

    @IBAction func onTouchPrevBtn(_ sender: Any) {
        scrollCurrentPage(isPrev: true)
        // set current date label to the selected date
        currentDate.text = selectedDate.toYYYYMMString()
    }

    @IBAction func onTouchNextBtn(_ sender: Any) {
        scrollCurrentPage(isPrev: false)
        currentDate.text = selectedDate.toYYYYMMString()
    }

    private func scrollCurrentPage(isPrev: Bool) {
        let cal = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = isPrev ? -1 : 1

        selectedDate = cal.date(byAdding: dateComponents, to: selectedDate)!
        calendarView.setCurrentPage(selectedDate, animated: true)
    }

    fileprivate let SHOW_NOTICE_PAGE = "show_notice_page"
    fileprivate let SHOW_SETTING_PAGE = "show_setting_page"
    fileprivate let SHOW_SCHEDULE_SETTING_PAGE = "show_schedule_setting_page"
    fileprivate let red = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
    fileprivate let gray = #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
    var scheduleList: [Date: [ScheduleEvent]] = [:]

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initData()
    }

    // MARK: - IBAction

    @IBAction func onTouchButton(_ sender: UIButton) {

        guard preventButtonClick, let tag = sender.viewTag else {
            return
        }

        switch tag {
        case .header_notice_button:
            performSegue(withIdentifier: SHOW_NOTICE_PAGE, sender: nil)

        case .header_setting_button:
            performSegue(withIdentifier: SHOW_SETTING_PAGE, sender: nil)

        case .schedule_list_add_button:
            performSegue(withIdentifier: SHOW_SCHEDULE_SETTING_PAGE, sender: nil)

        default:
            break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SHOW_SCHEDULE_SETTING_PAGE:
            if let vc = segue.destination as? ScheduleSettingViewController {
                vc.scheduleListener = self
                if let data = sender as? Dictionary<String, Any> {
                    vc.scheduleData = scheduleList[selectedDate.getDateOnly()]?[data["index"] as! Int]
                    vc.modifyingIndex = data["index"] as! Int
                }
            }
            break

        default:
            break
        }
        super.prepare(for: segue, sender: sender)
    }

    // MARK: - function

    func initView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ScheduleTableViewCell", bundle: nil), forCellReuseIdentifier: "ScheduleTableViewCell")
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.appearance.headerTitleColor = .clear
        calendarView.appearance.weekdayTextColor = .black
        calendarView.weekdayHeight = 30

        calendarView.appearance.weekdayFont = UIFont(name: "NotoSansCJKkr-Regular", size: 12)
        calendarView.appearance.titleFont = UIFont(name: "NotoSansCJKkr-Regular", size: 12)
        // set weekday locale
        calendarView.locale = Locale(identifier: "ko_KR")

        calendarView.appearance.todayColor = .clear
        calendarView.appearance.titleTodayColor = .red
        calendarView.appearance.todaySelectionColor = .clear

        calendarView.appearance.selectionColor = .clear
        calendarView.appearance.borderRadius = 0
        calendarView.appearance.headerMinimumDissolvedAlpha = 0

        calendarView.appearance.titleOffset = CGPoint(x: 0, y: -10)
        calendarView.appearance.titlePlaceholderColor = .clear

        selectedDateLabel.text = selectedDate.toMMDDString()
        selectedDateLabel.sizeToFit()

        currentDate.text = selectedDate.toYYYYMMString()

        // set currentdate label setonclicklistener
        currentDate.isUserInteractionEnabled = true
        currentDate.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTouchCurrentDateLabel)))
    }

    func initData() {

        // get schedule list from server
        let req_type: String = "guardian"
        let guardian_id: String = Global.shared.getPhoneNumber() // temp

        let param: [String: Any] = ["req_type": req_type, "guardian_id": guardian_id] as Dictionary //JSON 객체로 전송할 딕셔너리
        let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/get_schedules")!

        InfomarkClient().post(param: param, url: url, runnable: { [self] obj in
            let jsonObject = obj as! NSDictionary

            if let state = jsonObject["state"] as? String, state == "ok" {
                let objCArray = NSMutableArray(object: jsonObject["list"]!)
                var schedules = [ScheduleEvent]()
                if let swiftArray = objCArray as NSArray? as? [Any] {
                    for i in 0...swiftArray.count - 1 {
                        if let scheduleArray = swiftArray[i] as? [[String: Any]], scheduleArray.count > 0 {
                            for j in 0...scheduleArray.count - 1 {
                                let schedule = scheduleArray[j]
                                if let schedule_id = schedule["schedule_id"],
                                   let title = schedule["title"],
                                   let start_time = schedule["start_time"],
                                   let day = schedule["day"],
                                   let end_time = schedule["end_time"],
                                   let when = schedule["when"],
                                   let _repeat = schedule["repeat"] {
                                    let dayUtil = DayUtil()
                                    let startTime = dayUtil.parseDateTimeString("\(day) \(start_time)")
                                    let endTime = dayUtil.parseDateTimeString("\(day) \(end_time)")
                                    let scheduleEvent = ScheduleEvent(title as! String, DateInterval(start: startTime, end: endTime), dayUtil.parseUnit(_repeat as! String), dayUtil.parseUnit(when as! String))
                                    scheduleEvent.setId(schedule_id as! String)
                                    schedules.append(scheduleEvent)
                                }
                            }
                        }
                    }
                }

                // sort schedules by time
                schedules.sort(by: { $0.getStartEndTime().start > $1.getStartEndTime().start })

                schedules.forEach({event in
                    addSchedule(event, false, false)
                })

                selectedDate = today
                select(selectedDate)

                UNUserNotificationCenter.current().getPendingNotificationRequests { notiRequests in
//                        print(notiRequests)
                }
            } else {
                print("not found")
            }
        })
    }

    @objc func onTouchCurrentDateLabel() {
        if let datePickerDialog = UINib(nibName: "DatePickerDialog", bundle: nil).instantiate(withOwner: self, options: nil).first as? DatePickerDialog {
            guard let bounds = UIApplication.shared.windows.first?.bounds else {
                return
            }
            datePickerDialog.delegate = self
            datePickerDialog.frame = bounds
            datePickerDialog.initView(selectedDate)
            UIApplication.shared.windows.first?.addSubview(datePickerDialog)
        }
    }

    func select(_ date: Date) {
        calendarView.select(date)
        currentDate.text = date.toYYYYMMString()
        selectedDateLabel.text = date.toMMDDString()
        selectedDateLabel.sizeToFit()
        tableView.reloadData()
    }
}

extension ScheduleListViewController: DatePickerDialogDelegate {
    func didSelectedDate(_ date: Date) {
        selectedDate = date
        calendarView.setCurrentPage(selectedDate, animated: false)
        select(selectedDate)
    }
}

extension ScheduleListViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        if monthPosition == .current {
            calendarView.appearance.titleSelectionColor = selectedDate.isSameDay(date: calendarView.today!) ? .red : .black
        }
        // set the selected label to the selected date
        selectedDateLabel.text = date.toMMDDString()
        selectedDateLabel.sizeToFit()
        // no ellipsis
        selectedDateLabel.lineBreakMode = .byClipping

        tableView.reloadData()
    }

    open func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor? {
        // if the date is today, return red
        date.isSameDay(date: calendarView.today!) ? .red : .black
    }

    open func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        monthPosition == .current
    }

    open func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderSelectionColorFor date: Date) -> UIColor? {
        // set border color
        if let _ = scheduleList[date.getDateOnly()] {
            return red
        } else {
            // return colorliteral of green
            return UIColor(rgb: 0x00574B)
        }
    }

    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at monthPosition: FSCalendarMonthPosition) {
        // get cell of the date
        let label = cell.titleLabel
        // align the text label to the bottom of the cell
        label?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        // set the text label's text alignment
        label?.textAlignment = .center
        // add the text label to the calendar cell
        label?.numberOfLines = 0
        label?.sizeToFit()
        cell.addSubview(label!)

        if let schedule = scheduleList[date.getDateOnly()], schedule.count > 0, monthPosition == .current {
            for i in 0...schedule.count - 1 {
                // create a 1 px line
                let line = UIView(frame: CGRect(x: 0, y: cell.frame.height - 30 + CGFloat(i * 3), width: cell.frame.width - 18, height: 1))
                // set the color of the line if the schedule is enabled else set the color to gray
                line.backgroundColor = schedule[i].isEnabled() ? red : gray
                // get random boolean
                // center the line
                line.center.x = cell.contentView.center.x
                // add the line to the cell
                cell.contentView.addSubview(line)
            }
            cell.contentView.layoutIfNeeded()
        } else {
            // remove all the lines
            for view in cell.contentView.subviews {
                view.removeFromSuperview()
            }
        }
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let currentDate = calendar.currentPage
        self.currentDate.text = currentDate.toYYYYMMString()

        let dates = scheduleList.keys.filter { date in
            !calendar.currentPage.checkIfDateIsBetween(date)
        }
        for d in dates {
            if let schedule = scheduleList[d.getDateOnly()] {
                for i in 0...scheduleList[d.getDateOnly()]!.count - 1 {
                    if schedule[i].getMount() {
                        schedule[i].setUnmount()
                    }
                }
            }
        }
    }

    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        view.frame.size.height = bounds.height
        view.layoutIfNeeded()
    }

}

extension ScheduleListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let count = scheduleList[selectedDate.getDateOnly()]?.count ?? 0
        if count == 0 {
            // replace the tableview with the empty view
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            tableView.frame.size.height = CGFloat(21)
            // set the text
            label.text = "일정이 없습니다."
            // prevent label ellipsis
            label.lineBreakMode = .byClipping
            label.textColor = gray
            label.sizeToFit()
            tableView.backgroundView = label
            // tableview color clear
            tableView.backgroundColor = .clear
            // corner radius 0
            tableView.layer.cornerRadius = 0
        } else {
            // set tableview background gray
            tableView.backgroundColor = gray
            // set tableview border round
            tableView.layer.cornerRadius = 20
            tableView.backgroundView = nil
            tableView.frame.size.height = CGFloat(50 * count + 10)
            // set inset padding to 10
            tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        }
        self.view.layoutIfNeeded()
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleTableViewCell", for: indexPath) as! ScheduleTableViewCell
        cell.model = scheduleList[selectedDate.getDateOnly()]![indexPath.row]
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SHOW_SCHEDULE_SETTING_PAGE, sender: ["data": scheduleList[selectedDate.getDateOnly()]![indexPath.row], "index": indexPath.row])
    }
}
