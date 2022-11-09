//
//  AlarmSettingViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/06/07.
//

import UIKit

protocol AlertListener {
    func addAlert(id: String, title: String, alertTime: Date, alertDateRange: DateInterval, dayArray: [DayOfWeek], upload: Bool)
//    func modifyAlert(id: String, isEnabled: Bool, title: String, time: Date, alertDateRange: DateInterval, pillPeriod: [DayOfWeek])
    func modifyAlert(id: String, newValue: AlarmModel)
}

class AlarmSettingViewController: BaseViewController {

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var confirmButton: UIButton!

    @IBOutlet var nameTextField: UITextField!

    @IBOutlet var ampmPickerView: UIPickerView!
    @IBOutlet var hourPickerView: UIPickerView!
    @IBOutlet var minutePickerView: UIPickerView!

    private var isModifying: Bool = false

    private var ampm: Int = 0
    private var hour: Int = 0
    private var minute: Int = 0

    @IBOutlet var startYearPickerView: UIPickerView!
    @IBOutlet var startMonthPickerView: UIPickerView!
    @IBOutlet var startDayPickerView: UIPickerView!

    private var startYear: Int?
    private var startMonth: Int?
    private var startDay: Int?

    @IBOutlet var endYearPickerView: UIPickerView!
    @IBOutlet var endMonthPickerView: UIPickerView!
    @IBOutlet var endDayPickerView: UIPickerView!

    private var endYear: Int?
    private var endMonth: Int?
    private var endDay: Int?

    private var dayArray: [DayOfWeek] = []

    @IBOutlet var periodButtons: [UIButton]!

    private var yearArray: Array<String> = []

    public var mListener: AlertListener?

    var alarmData: AlarmModel?

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    // MARK: - IBAction

    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else {
            return
        }

        switch tag {
        case .alarm_setting_cancel_button:
            self.dismiss(animated: true)

        case .alarm_setting_delete_button:
            showCancelPopup()

        case .alarm_setting_everyday_button:
            sender.isSelected = !sender.isSelected
            sender.layer.borderColor = sender.isSelected ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)

        case .alarm_setting_confirm_button:
            let startDate = DateComponents(timeZone: TimeZone.current, year: startYear, month: startMonth, day: startDay, hour: 0, minute: 0, second: 0)
            let endDate = DateComponents(timeZone: TimeZone.current, year: endYear, month: endMonth, day: endDay, hour: 23, minute: 59, second: 59)
            let startCal = Calendar.current.date(from: startDate)!
            let endCal = Calendar.current.date(from: endDate)!
            let alertTime = Calendar.current.date(from: DateComponents(timeZone: TimeZone.current, year: startYear, month: startMonth, day: startDay, hour: ampm * 12 + hour, minute: minute, second: 0))!
            if let alarmData = alarmData {   // 복약알림 설정일 경우
//                mListener?.modifyAlert(id: "0", title: nameTextField.text!)
//                mListener?.modifyAlert(id: alarmData.getId()!, isEnabled: alarmData.checkEnabled()!, title: nameTextField.text!, time: alertTime, alertDateRange: DateInterval(start: startCal, end: endCal), pillPeriod: dayArray)
                alarmData.setTitle(title: nameTextField.text!)
                alarmData.setPillCalendar(pillCalendar: alertTime)
                alarmData.setAlertDateRange(alertDateRange: DateInterval(start: startCal, end: endCal))
                alarmData.setDayArray(pill_period: dayArray)
                mListener?.modifyAlert(id: alarmData.getId()!, newValue: alarmData)
            } else {    // 복약알림 추가일 경우
                if (startCal <= endCal) {
                    mListener?.addAlert(id: CommonUtil().generateRandom(length: 10), title: nameTextField.text!, alertTime: alertTime, alertDateRange: DateInterval(start: startCal, end: endCal), dayArray: dayArray, upload: true)
                }

            }
            dismiss(animated: true)

        default:
            break
        }
    }

    @IBAction func onTouchPeriod(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.layer.borderColor = sender.isSelected ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
        switch sender.titleLabel!.text! {
        case "월":
            addOrRemove(dayOfWeek: .MONDAY)
            break
        case "화":
            addOrRemove(dayOfWeek: .TUESDAY)
            break
        case "수":
            addOrRemove(dayOfWeek: .WEDNESDAY)
            break
        case "목":
            addOrRemove(dayOfWeek: .THURSDAY)
            break
        case "금":
            addOrRemove(dayOfWeek: .FRIDAY)
            break
        case "토":
            addOrRemove(dayOfWeek: .SATURDAY)
            break
        case "일":
            addOrRemove(dayOfWeek: .SUNDAY)
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

        if let data = alarmData {   // 복약알림 수정일 경우
            isModifying = true
            titleLabel.text = "복약알림 설정"
            deleteButton.isHidden = false
            confirmButton.setTitle("확인", for: .normal)
            nameTextField.text = data.getTitle()
            ampm = (data.getPillCalendar()!.getHour()!) / 12
            hour = (data.getPillCalendar()!.getHour()!) % 12
            minute = data.getPillCalendar()!.getMinute()!
            ampmPickerView.selectRow(ampm, inComponent: 0, animated: false)
            hourPickerView.selectRow(hour == 0 ? 11 : hour - 1, inComponent: 0, animated: false)
            startYear = data.getAlertDateRange()?.start.getYear()
            startMonth = data.getAlertDateRange()?.start.getMonth()
            startDay = data.getAlertDateRange()?.start.getDay()
            endYear = data.getAlertDateRange()?.end.getYear()
            endMonth = data.getAlertDateRange()?.end.getMonth()
            endDay = data.getAlertDateRange()?.end.getDay()
            dayArray = data.getDayArray()
            for el in dayArray {
                switch el {
                case .MONDAY:
                    periodButtons[0].isSelected = true
                    periodButtons[0].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                case .TUESDAY:
                    periodButtons[1].isSelected = true
                    periodButtons[1].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                case .WEDNESDAY:
                    periodButtons[2].isSelected = true
                    periodButtons[2].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                case .THURSDAY:
                    periodButtons[3].isSelected = true
                    periodButtons[3].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                case .FRIDAY:
                    periodButtons[4].isSelected = true
                    periodButtons[4].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                case .SATURDAY:
                    periodButtons[5].isSelected = true
                    periodButtons[5].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                case .SUNDAY:
                    periodButtons[6].isSelected = true
                    periodButtons[6].layer.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
                    break
                }
            }
            minutePickerView.selectRow(minute / 5, inComponent: 0, animated: false)
            startYearPickerView.selectRow(startYear! - currentYear, inComponent: 0, animated: false)
            startMonthPickerView.selectRow(startMonth! - 1, inComponent: 0, animated: false)
            startDayPickerView.selectRow(startDay! - 1, inComponent: 0, animated: false)
            endYearPickerView.selectRow(endYear! - currentYear, inComponent: 0, animated: false)
            endMonthPickerView.selectRow(endMonth! - 1, inComponent: 0, animated: false)
            endDayPickerView.selectRow(endDay! - 1, inComponent: 0, animated: false)
        } else {    // 복약알림 추가일 경우
            isModifying = false
            titleLabel.text = "복약알림 추가"
            deleteButton.isHidden = true
            confirmButton.setTitle("추가", for: .normal)
            var now = Date()
            ampm = (now.getHour()!) / 12
            ampmPickerView.selectRow(ampm, inComponent: 0, animated: false)
            hour = (now.getHour()!) % 12
            hourPickerView.selectRow(hour == 0 ? 11 : hour - 1, inComponent: 0, animated: false)
            minute = now.getMinute()!
            minutePickerView.selectRow(minute / 5, inComponent: 0, animated: false)
            startYear = now.getYear()
            startYearPickerView.selectRow(startYear! - currentYear, inComponent: 0, animated: false)
            startMonth = now.getMonth()
            startMonthPickerView.selectRow(startMonth! - 1, inComponent: 0, animated: false)
            startDay = now.getDay()
            startDayPickerView.selectRow(startDay! - 1, inComponent: 0, animated: false)
            endYear = now.getYear()
            endYearPickerView.selectRow(endYear! - currentYear, inComponent: 0, animated: false)
            endMonth = now.getMonth()
            endMonthPickerView.selectRow(endMonth! - 1, inComponent: 0, animated: false)
            endDay = now.getDay()
            endDayPickerView.selectRow(endDay! - 1, inComponent: 0, animated: false)
            dayArray = []
        }

    }

    func showCancelPopup() {
        if let cancelPopup = UINib(nibName: "CancelPopup", bundle: nil).instantiate(withOwner: self, options: nil).first as? CancelPopup {
            guard let bounds = UIApplication.shared.windows.first?.bounds else {
                return
            }
            cancelPopup.delegate = self
            cancelPopup.frame = bounds
            cancelPopup.initView("복약설정을 삭제하시겠습니까?")
            UIApplication.shared.windows.first?.addSubview(cancelPopup)
        }
    }

    private func addOrRemove(dayOfWeek: DayOfWeek) {
        if ((dayArray.contains(dayOfWeek))) {
            dayArray = dayArray.filter {
                $0 != dayOfWeek
            }
        } else {
            dayArray.append(dayOfWeek)
        }
    }

}

// MARK: - Extension UIPickerViewDelegate, UIPickerViewDataSource

extension AlarmSettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case ampmPickerView:
            return AM_PM_ARRAY.count

        case hourPickerView:
            return HOUR_ARRAY.count

        case minutePickerView:
            return MINUTE_ARRAY.count

        case startYearPickerView, endYearPickerView:
            return yearArray.count

        case startMonthPickerView, endMonthPickerView:
            return MONTH_ARRAY.count

        case startDayPickerView, endDayPickerView:
            return DAY_ARRAY.count

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
        let orange = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
        let gray = #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
        label.textColor = pickerView.selectedRow(inComponent: component) == row ? orange : gray

        pickerView.subviews[1].isHidden = true

        switch pickerView {
        case ampmPickerView:
            label.text = AM_PM_ARRAY[row]
            let selected = AM_PM_ARRAY[row]
            if (selected == "오전") {
                ampm = 0
            } else if (selected == "오후") {
                ampm = 1
            }
//            if(isModifying) {
//                if isAfternoon {
//                    label.textColor = ampm == 1 ? orange : gray
//                } else {
//                    label.textColor = ampm == 0 ? orange : gray
//                }
//            }
            break
        case hourPickerView:
            label.text = HOUR_ARRAY[row]
            hour = Int(HOUR_ARRAY[row])!
            break
        case minutePickerView:
            label.text = MINUTE_ARRAY[row]
            minute = Int(MINUTE_ARRAY[row])!
            break
        case startYearPickerView:
            label.text = yearArray[row]
            startYear = Int(yearArray[row])!
            break
        case startMonthPickerView:
            label.text = MONTH_ARRAY[row]
            startMonth = Int(MONTH_ARRAY[row])!
            break
        case startDayPickerView:
            label.text = DAY_ARRAY[row]
            startDay = Int(DAY_ARRAY[row])!
            break
        case endYearPickerView:
            label.text = yearArray[row]
            endYear = Int(yearArray[row])!
            break
        case endMonthPickerView:
            label.text = MONTH_ARRAY[row]
            endMonth = Int(MONTH_ARRAY[row])!
            break
        case endDayPickerView:
            label.text = DAY_ARRAY[row]
            endDay = Int(DAY_ARRAY[row])!
            break
        default:
            break
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case ampmPickerView:
            break

        case hourPickerView:
            break

        case minutePickerView:
            break

        case startYearPickerView:
            break

        case startMonthPickerView:
            break

        case startDayPickerView:
            break

        case endYearPickerView:
            break

        case endMonthPickerView:
            break

        case endDayPickerView:
            break

        default:
            break
        }

        pickerView.reloadAllComponents()
    }
}

// MARK: - Extension CancelPopupDelegate

extension AlarmSettingViewController: CancelPopupDelegate {
    func didCompleted() {
        self.dismiss(animated: true)
    }
}

// MARK: - Extension UITextFieldDelegate

extension AlarmSettingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
