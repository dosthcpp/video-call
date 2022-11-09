//
//  TimeSettingViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/06/02.
//

import UIKit

protocol TimeSettingViewDelegate: class {
    func setSelectedTime(_ time: String)
}

class TimeSettingViewController: BaseViewController {
    
    @IBOutlet var yearPickerView: UIPickerView!
    @IBOutlet var monthPickerView: UIPickerView!
    @IBOutlet var dayPickerView: UIPickerView!
    @IBOutlet var ampmPickerView: UIPickerView!
    @IBOutlet var hourPickerView: UIPickerView!
    @IBOutlet var minutePickerView: UIPickerView!
    
    @IBOutlet var timeButtons: [UIButton]!
    
    private var yearArray: Array<String> = []
    
    private var selectedYearIndex: Int = 0
    private var selectedMonthIndex: Int = 0
    private var selectedDayIndex: Int = 0
    private var selectedAmPmIndex: Int = 0
    private var selectedHourIndex: Int = 0
    private var selectedMinuteIndex: Int = 0
    private var selectedTime: Int = 0
    
    weak var delegate: TimeSettingViewDelegate?
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .time_setting_cancel_button:
            self.dismiss(animated: true)
            
        case .time_setting_minute_button, .time_setting_one_hour_button, .time_setting_two_hour_button:
            for btn in timeButtons {
                btn.isSelected = false
                btn.borderColor = #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
            }
            sender.isSelected = true
            sender.borderColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            selectedTime = sender.tag
            
        case .time_setting_confirm_button:
            if selectedTime == 0 {
                CommonUtil().showToast("통화시간을 선택해주세요.")
                return
            }
            
            let selectedYear = yearArray[selectedYearIndex]
            let selectedMonth = MONTH_ARRAY[selectedMonthIndex]
            let selectedDay = DAY_ARRAY[selectedDayIndex]
            let selectedAmPm = AM_PM_ARRAY[selectedAmPmIndex]
            let selectedHour = HOUR_ARRAY[selectedHourIndex]
            let selectedMinute = MINUTE_ARRAY[selectedMinuteIndex]
            let time = selectedTime == 30 ? "\(selectedTime)분" : "\(selectedTime)시간"
            
            delegate?.setSelectedTime("\(selectedYear)년 \(selectedMonth)월 \(selectedDay)일\n\(selectedAmPm) \(selectedHour):\(selectedMinute) \(time)")
            self.dismiss(animated: true)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        let currentYear = Calendar.current.component(.year, from: Date())
        yearArray = (currentYear...currentYear + 20).map { String($0) }
    }
}

// MARK: - Extension UIPickerViewDelegate, UIPickerViewDataSource
extension TimeSettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case yearPickerView:
            return yearArray.count
            
        case monthPickerView:
            return MONTH_ARRAY.count
            
        case dayPickerView:
            return DAY_ARRAY.count
            
        case ampmPickerView:
            return AM_PM_ARRAY.count
            
        case hourPickerView:
            return HOUR_ARRAY.count
            
        case minutePickerView:
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
        case yearPickerView:
            label.text = yearArray[row]
            
        case monthPickerView:
            label.text = MONTH_ARRAY[row]
            
        case dayPickerView:
            label.text = DAY_ARRAY[row]
            
        case ampmPickerView:
            label.text = AM_PM_ARRAY[row]
            
        case hourPickerView:
            label.text = HOUR_ARRAY[row]
            
        case minutePickerView:
            label.text = MINUTE_ARRAY[row]
            
        default:
            break
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case yearPickerView:
            selectedYearIndex = row
            
        case monthPickerView:
            selectedMonthIndex = row
            
        case dayPickerView:
            selectedDayIndex = row
            
        case ampmPickerView:
            selectedAmPmIndex = row
            
        case hourPickerView:
            selectedHourIndex = row
            
        case minutePickerView:
            selectedMinuteIndex = row
            
        default:
            break
        }
        
        pickerView.reloadAllComponents()
    }
}
