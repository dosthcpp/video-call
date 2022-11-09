//
//  DatePickerDialog.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/12.
//

import Foundation
import UIKit

protocol DatePickerDialogDelegate: class {
    func didSelectedDate(_ date: Date)
}

class DatePickerDialog: UIView {
    let today = Date()

    @IBOutlet var yearPickerView: UIPickerView!
    @IBOutlet var monthPickerView: UIPickerView!
    @IBOutlet var datePickerView: UIPickerView!

    // selected year
    var selectedYear: Int?
    // selected month
    var selectedMonth: Int?
    // selected date
    var selectedDate: Int?

    private var yearArray: Array<String> = []

    // delegate
    weak var delegate: DatePickerDialogDelegate?
    
    @IBAction func cancelDialog(_ sender: Any) {
        removeFromSuperview()
    }
    
    @IBAction func confirmDialog(_ sender: Any) {
        removeFromSuperview()
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth
        dateComponents.day = selectedDate
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        delegate?.didSelectedDate(date)
    }
    
    func initView(_ date: Date) {
        yearPickerView.delegate = self
        yearPickerView.dataSource = self
        monthPickerView.delegate = self
        monthPickerView.dataSource = self
        datePickerView.delegate = self
        datePickerView.dataSource = self

        selectedYear = date.getYear()
        selectedMonth = date.getMonth()
        selectedDate = date.getDay()

        let currentYear = Calendar.current.component(.year, from: Date())
        yearArray = (currentYear...currentYear + 20).map { String($0) }

        // select row following the value of date
        yearPickerView.selectRow(selectedYear! - currentYear, inComponent: 0, animated: false)
        monthPickerView.selectRow(selectedMonth! - 1, inComponent: 0, animated: false)
        datePickerView.selectRow(selectedDate! - 1, inComponent: 0, animated: false)
    }
}

extension DatePickerDialog: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case yearPickerView:
            return yearArray.count

        case monthPickerView:
            return MONTH_ARRAY.count

        case datePickerView:
            return DAY_ARRAY.count

        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.height / 5
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.textColor = pickerView.selectedRow(inComponent: component) == row ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)

        pickerView.subviews[1].isHidden = true

        switch pickerView {
        case yearPickerView:
            label.text = yearArray[row] + "년"

        case monthPickerView:
            label.text = MONTH_ARRAY[row] + "월"

        case datePickerView:
            label.text = DAY_ARRAY[row] + "일"

        default:
            break
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {


        switch pickerView {
        case yearPickerView:
            selectedYear = Int(yearArray[row]) ?? today.getYear()!

        case monthPickerView:
            selectedMonth = Int(MONTH_ARRAY[row]) ?? today.getMonth()!

        case datePickerView:
            selectedDate = Int(DAY_ARRAY[row]) ?? today.getDay()!

        default:
            break
        }

        pickerView.reloadAllComponents()
    }
}
