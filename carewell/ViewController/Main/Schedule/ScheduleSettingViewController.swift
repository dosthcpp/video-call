//
//  ScheduleSettingViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/06/07.
//

import UIKit

protocol ScheduleListener: AnyObject {
    func addSchedule(_ schedule: ScheduleEvent, _ upload: Bool, _ willSelect: Bool)
    func modifySchedule(_ schedule: ScheduleEvent, _ index: Int, _ upload: Bool)
    func deleteSchedule(_ index: Int)
}

class ScheduleSettingViewController: BaseViewController {

    @IBOutlet var titleTextField: UITextField!

    @IBOutlet var startTimeLabel: UILabel!
    @IBOutlet var endTimeLabel: UILabel!

    @IBOutlet var startContainerView: UIView!
    @IBOutlet var endContainerView: UIView!

    @IBOutlet var startYearPickerView: UIPickerView!
    @IBOutlet var startMonthPickerView: UIPickerView!
    @IBOutlet var startDayPickerView: UIPickerView!
    @IBOutlet var startAmpmPickerView: UIPickerView!
    @IBOutlet var startHourPickerView: UIPickerView!
    @IBOutlet var startMinutePickerView: UIPickerView!

    @IBOutlet var endYearPickerView: UIPickerView!
    @IBOutlet var endMonthPickerView: UIPickerView!
    @IBOutlet var endDayPickerView: UIPickerView!
    @IBOutlet var endAmpmPickerView: UIPickerView!
    @IBOutlet var endHourPickerView: UIPickerView!
    @IBOutlet var endMinutePickerView: UIPickerView!

    @IBOutlet var repeatOptionLabel: UILabel!
    @IBOutlet var repeatButtons: [UIButton]!
    @IBOutlet var repeatOptionDivider: UIView!
    
    
    @IBOutlet var alarmOptionLabel: UILabel!
    @IBOutlet var alarmButtons: [UIButton]!
    @IBOutlet var alarmOptionDivider: UIView!
    fileprivate var SHOW_SCHEDULE_SETTING_PAGE = "show_schedule_setting_page"

    private var yearArray: Array<String> = []

    private var selectedStartYearIndex: Int = 0
    private var selectedStartMonthIndex: Int = 0
    private var selectedStartDayIndex: Int = 0
    private var selectedStartAmPmIndex: Int = 0
    private var selectedStartHourIndex: Int = 0
    private var selectedStartMinuteIndex: Int = 0

    private var selectedEndYearIndex: Int = 0
    private var selectedEndMonthIndex: Int = 0
    private var selectedEndDayIndex: Int = 0
    private var selectedEndAmPmIndex: Int = 0
    private var selectedEndHourIndex: Int = 0
    private var selectedEndMinuteIndex: Int = 0

    public var scheduleListener: ScheduleListener?
    public var scheduleData: ScheduleEvent?
    public var modifyingIndex = -1
    public var isModifying = false

    private var when: TimeUnit = .NONE
    private var repeatOption: TimeUnit = .NONE

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    // MARK: - IBAction

    @IBAction func onTouchBackground(_ sender: UIControl) {
        titleTextField.resignFirstResponder()
    }

    @IBAction func onTouchButton(_ sender: UIButton) {
        titleTextField.resignFirstResponder()
        guard preventButtonClick, let tag = sender.viewTag else {
            return
        }

        switch tag {
        case .schedule_setting_cancel_button:
            self.dismiss(animated: true)

        case .schedule_setting_delete_button:
            if -1 != modifyingIndex {
                scheduleListener?.deleteSchedule(modifyingIndex)
            }
            showCancelPopup()

        case .schedule_setting_start_button:
            startContainerView.isHidden = !startContainerView.isHidden

        case .schedule_setting_end_button:
            endContainerView.isHidden = !endContainerView.isHidden

        case .schedule_setting_confirm_button:
            let startDate = Date.of(year: Int(yearArray[selectedStartYearIndex])!, month: Int(MONTH_ARRAY[selectedStartMonthIndex])!, day: Int(DAY_ARRAY[selectedStartDayIndex])!, hour: (Int(HOUR_ARRAY[selectedStartHourIndex])!) + 12 * selectedStartAmPmIndex, minute: Int(MINUTE_ARRAY[selectedStartMinuteIndex])!)
            let endDate = Date.of(year: Int(yearArray[selectedEndYearIndex])!, month: Int(MONTH_ARRAY[selectedEndMonthIndex])!, day: Int(DAY_ARRAY[selectedEndDayIndex])!, hour: (Int(HOUR_ARRAY[selectedEndHourIndex])!) + 12 * selectedEndAmPmIndex, minute: Int(MINUTE_ARRAY[selectedEndMinuteIndex])!)
            let scheduleEvent = ScheduleEvent(titleTextField.text ?? "", DateInterval(start: startDate, end: endDate), repeatOption, when)
            if !isModifying {
                scheduleListener?.addSchedule(scheduleEvent, true, true)
            } else if let _ = scheduleData {
                scheduleEvent.setId(scheduleData!.getId())
                scheduleListener?.modifySchedule(scheduleEvent, modifyingIndex, true)
            }
            self.dismiss(animated: true)
            break

        default:
            break
        }
    }

    @IBAction func onTouchRepeat(_ sender: UIButton) {
        titleTextField.resignFirstResponder()

        for btn in repeatButtons {
            btn.isSelected = false
            btn.layer.borderColor = #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
        }
        sender.isSelected = true
        sender.layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)

        // get the selected index
        let index = repeatButtons.firstIndex(of: sender)
        // set repeat option to scheduleData
        switch (index) {
        case 0:
            scheduleData?.setRepeatOption(.EVERYDAY)
            repeatOption = .EVERYDAY
            break
        case 1:
            scheduleData?.setRepeatOption(.EVERYWEEK)
            repeatOption = .EVERYWEEK
            break
        case 2:
            scheduleData?.setRepeatOption(.EVERYMONTH)
            repeatOption = .EVERYMONTH
            break
        case 3:
            scheduleData?.setRepeatOption(.EVERYYEAR)
            repeatOption = .EVERYYEAR
            break
        default:
            break
        }
    }

    @IBAction func onTouchAlarm(_ sender: UIButton) {
        titleTextField.resignFirstResponder()

        for btn in alarmButtons {
            btn.isSelected = false
            btn.layer.borderColor = #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
        }
        sender.isSelected = true
        sender.layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)

        // get the selected index
        let index = alarmButtons.firstIndex(of: sender)
        // set alarm option to scheduleData
        switch (index) {
        case 0:
            scheduleData?.setWhen(.BEFORE_10MINUTES)
            when = .BEFORE_10MINUTES
            break
        case 1:
            scheduleData?.setWhen(.BEFORE_1HOUR)
            when = .BEFORE_1HOUR
            break
        case 2:
            scheduleData?.setWhen(.BEFORE_1DAY)
            when = .BEFORE_1DAY
            break
        default:
            break
        }
    }

    // MARK: - function

    func initView() {
        let currentYear = Calendar.current.component(.year, from: Date())
        yearArray = (currentYear...currentYear + 20).map {
            String($0)
        }

        if let _ = scheduleData {
            isModifying = true
            // hide start date pickerview
            startYearPickerView.isHidden = true
            startMonthPickerView.isHidden = true
            startDayPickerView.isHidden = true
            // hide end date pickerview
            endYearPickerView.isHidden = true
            endMonthPickerView.isHidden = true
            endDayPickerView.isHidden = true

            // group other picker views and horizontally center them
            let startStackView = UIStackView(arrangedSubviews: [startAmpmPickerView, startHourPickerView, startMinutePickerView])
            startStackView.axis = .horizontal
            startStackView.distribution = .fillEqually
            startStackView.alignment = .leading
            startStackView.spacing = 0
            startContainerView.addSubview(startStackView)
            startStackView.translatesAutoresizingMaskIntoConstraints = false
            startStackView.topAnchor.constraint(equalTo: startContainerView.topAnchor).isActive = true
            startStackView.bottomAnchor.constraint(equalTo: startContainerView.bottomAnchor).isActive = true
            startStackView.leadingAnchor.constraint(equalTo: startContainerView.leadingAnchor, constant: CGFloat(60.0)).isActive = true
            startStackView.trailingAnchor.constraint(equalTo: startContainerView.trailingAnchor, constant: CGFloat(-60.0)).isActive = true
            // endStackview, too
            let endStackView = UIStackView(arrangedSubviews: [endAmpmPickerView, endHourPickerView, endMinutePickerView])
            endStackView.axis = .horizontal
            endStackView.distribution = .fillEqually
            endStackView.alignment = .leading
            endStackView.spacing = 0
            endContainerView.addSubview(endStackView)
            endStackView.translatesAutoresizingMaskIntoConstraints = false
            endStackView.topAnchor.constraint(equalTo: endContainerView.topAnchor).isActive = true
            endStackView.bottomAnchor.constraint(equalTo: endContainerView.bottomAnchor).isActive = true
            endStackView.leadingAnchor.constraint(equalTo: endContainerView.leadingAnchor, constant: CGFloat(60.0)).isActive = true
            endStackView.trailingAnchor.constraint(equalTo: endContainerView.trailingAnchor, constant: CGFloat(-60.0)).isActive = true
            // group repeat option label, buttons and divider, and then hide them
            // get y coordinate of option divider
            let repeatOptionLabelY = repeatOptionDivider.frame.origin.y
            // get y coordinate of alarm optiondivider
            let alarmOptionLabelY = alarmOptionDivider.frame.origin.y
            // get difference of them
            let diff = repeatOptionLabelY - alarmOptionLabelY
            repeatOptionLabel.isHidden = true
            repeatButtons.forEach({ button in
                button.isHidden = true
            })
            repeatOptionDivider.isHidden = true
            // translate alarm views up
            alarmOptionLabel.transform = CGAffineTransform(translationX: 0, y: diff)
            alarmButtons.forEach({ button in
                button.transform = CGAffineTransform(translationX: 0, y: diff)
            })
            alarmOptionDivider.transform = CGAffineTransform(translationX: 0, y: diff)
        }

        // find value in array using scheduledata
        let startDate: Date = scheduleData?.getStartEndTime().start ?? Date()
        selectedStartYearIndex = yearArray.firstIndex(of: String(startDate.getYear()!)) ?? 0
        selectedStartMonthIndex = MONTH_ARRAY.firstIndex(of: String(startDate.getMonth()!.zeroPadding())) ?? 0
        selectedStartDayIndex = DAY_ARRAY.firstIndex(of: String(startDate.getDay()!.zeroPadding())) ?? 0
        selectedStartHourIndex = HOUR_ARRAY.firstIndex(of: String(startDate.getHour()! % 12)) ?? 0
        selectedStartAmPmIndex = startDate.getHour()! / 12
        selectedStartMinuteIndex = MINUTE_ARRAY.firstIndex(of: String((Int(startDate.getMinute()! / 5 * 5)))) ?? 0
        // select value in picker view
        startYearPickerView.selectRow(selectedStartYearIndex, inComponent: 0, animated: false)
        startMonthPickerView.selectRow(selectedStartMonthIndex, inComponent: 0, animated: false)
        startDayPickerView.selectRow(selectedStartDayIndex, inComponent: 0, animated: false)
        startHourPickerView.selectRow(selectedStartHourIndex, inComponent: 0, animated: false)
        startMinutePickerView.selectRow(selectedStartMinuteIndex, inComponent: 0, animated: false)
        startAmpmPickerView.selectRow(selectedStartAmPmIndex, inComponent: 0, animated: false)

        let endDate: Date = scheduleData?.getStartEndTime().end ?? Date()
        selectedEndYearIndex = yearArray.firstIndex(of: String(endDate.getYear()!)) ?? 0
        selectedEndMonthIndex = MONTH_ARRAY.firstIndex(of: String(endDate.getMonth()!.zeroPadding())) ?? 0
        selectedEndDayIndex = DAY_ARRAY.firstIndex(of: String(endDate.getDay()!.zeroPadding())) ?? 0
        selectedEndHourIndex = HOUR_ARRAY.firstIndex(of: String(endDate.getHour()! % 12)) ?? 0
        selectedEndAmPmIndex = endDate.getHour()! / 12
        selectedEndMinuteIndex = MINUTE_ARRAY.firstIndex(of: String((Int(endDate.getMinute()! / 5 * 5)))) ?? 0
        // select value in picker view
        endYearPickerView.selectRow(selectedEndYearIndex, inComponent: 0, animated: false)
        endMonthPickerView.selectRow(selectedEndMonthIndex, inComponent: 0, animated: false)
        endDayPickerView.selectRow(selectedEndDayIndex, inComponent: 0, animated: false)
        endHourPickerView.selectRow(selectedEndHourIndex, inComponent: 0, animated: false)
        endMinutePickerView.selectRow(selectedEndMinuteIndex, inComponent: 0, animated: false)
        endAmpmPickerView.selectRow(selectedEndAmPmIndex, inComponent: 0, animated: false)

        // set title text field
        titleTextField.text = scheduleData?.getTitle()

        // set repeat option
        repeatOption = scheduleData?.getRepeatOption() ?? .NONE
        switch (repeatOption) {
        case .EVERYDAY:
            repeatButtons[0].isSelected = true
            repeatButtons[0].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        case .EVERYWEEK:
            repeatButtons[1].isSelected = true
            repeatButtons[1].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        case .EVERYWEEK:
            repeatButtons[2].isSelected = true
            repeatButtons[2].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        case .EVERYYEAR:
            repeatButtons[3].isSelected = true
            repeatButtons[3].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        default:
            break
        }

        // set alarm option
        when = scheduleData?.getWhen() ?? .BEFORE_10MINUTES
        switch (when) {
        case .BEFORE_10MINUTES:
            alarmButtons[0].isSelected = true
            alarmButtons[0].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        case .BEFORE_1HOUR:
            alarmButtons[1].isSelected = true
            alarmButtons[1].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        case .BEFORE_1DAY:
            alarmButtons[2].isSelected = true
            alarmButtons[2].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            break
        default:
            break
        }

        updateTime()
    }

    func updateTime() {
        startTimeLabel.text = "\(yearArray[selectedStartYearIndex])년 \(MONTH_ARRAY[selectedStartMonthIndex])월\(DAY_ARRAY[selectedStartDayIndex])일 \(AM_PM_ARRAY[selectedStartAmPmIndex]) \(HOUR_ARRAY[selectedStartHourIndex]):\(MINUTE_ARRAY[selectedStartMinuteIndex])"
        endTimeLabel.text = "\(yearArray[selectedEndYearIndex])년 \(MONTH_ARRAY[selectedEndMonthIndex])월\(DAY_ARRAY[selectedEndDayIndex])일 \(AM_PM_ARRAY[selectedEndAmPmIndex]) \(HOUR_ARRAY[selectedEndHourIndex]):\(MINUTE_ARRAY[selectedEndMinuteIndex])"

    }

    func showCancelPopup() {
        if let cancelPopup = UINib(nibName: "CancelPopup", bundle: nil).instantiate(withOwner: self, options: nil).first as? CancelPopup {
            guard let bounds = UIApplication.shared.windows.first?.bounds else {
                return
            }
            cancelPopup.delegate = self
            cancelPopup.frame = bounds
            cancelPopup.initView("일정을 삭제하시겠습니까?")
            UIApplication.shared.windows.first?.addSubview(cancelPopup)
        }
    }
}

// MARK: - Extension CancelPopupDelegate

extension ScheduleSettingViewController: CancelPopupDelegate {
    func didCompleted() {
        self.dismiss(animated: true)
    }
}

// MARK: - Extension UIPickerViewDelegate, UIPickerViewDataSource

extension ScheduleSettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case startYearPickerView, endYearPickerView:
            return yearArray.count

        case startMonthPickerView, endMonthPickerView:
            return MONTH_ARRAY.count

        case startDayPickerView, endDayPickerView:
            return DAY_ARRAY.count

        case startAmpmPickerView, endAmpmPickerView:
            return AM_PM_ARRAY.count

        case startHourPickerView, endHourPickerView:
            return HOUR_ARRAY.count

        case startMinutePickerView, endMinutePickerView:
            return MINUTE_ARRAY.count

        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.height / 4
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.textColor = pickerView.selectedRow(inComponent: component) == row ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)

        pickerView.subviews[1].isHidden = true

        switch pickerView {
        case startYearPickerView, endYearPickerView:
            label.text = yearArray[row]

        case startMonthPickerView, endMonthPickerView:
            label.text = MONTH_ARRAY[row]

        case startDayPickerView, endDayPickerView:
            label.text = DAY_ARRAY[row]

        case startAmpmPickerView, endAmpmPickerView:
            label.text = AM_PM_ARRAY[row]

        case startHourPickerView, endHourPickerView:
            label.text = HOUR_ARRAY[row]

        case startMinutePickerView, endMinutePickerView:
            label.text = MINUTE_ARRAY[row]

        default:
            break
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case startYearPickerView:
            selectedStartYearIndex = row

        case startMonthPickerView:
            selectedStartMonthIndex = row

        case startDayPickerView:
            selectedStartDayIndex = row

        case startAmpmPickerView:
            selectedStartAmPmIndex = row

        case startHourPickerView:
            selectedStartHourIndex = row

        case startMinutePickerView:
            selectedStartMinuteIndex = row

        case endYearPickerView:
            selectedEndYearIndex = row

        case endMonthPickerView:
            selectedEndMonthIndex = row

        case endDayPickerView:
            selectedEndDayIndex = row

        case endAmpmPickerView:
            selectedEndAmPmIndex = row

        case endHourPickerView:
            selectedEndHourIndex = row

        case endMinutePickerView:
            selectedEndMinuteIndex = row

        default:
            break
        }

        pickerView.reloadAllComponents()

        updateTime()
    }
}

// MARK: - Extension

extension ScheduleSettingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        return true
    }
}
