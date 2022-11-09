//
//  AlarmListViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit

class AlarmListViewController: BaseViewController, AlertListener {
    
    @IBOutlet var currentTableView: UITableView!
    @IBOutlet var preTableView: UITableView!
    
    @IBOutlet var currentTableViewHeight: NSLayoutConstraint!
    @IBOutlet var preTableViewHeight: NSLayoutConstraint!
    
    fileprivate let SHOW_NOTICE_PAGE = "show_notice_page"
    fileprivate let SHOW_SETTING_PAGE = "show_setting_page"
    fileprivate let SHOW_ALARM_SETTING_PAGE = "show_alarm_setting_page"
    
    public var currentModelList: [AlarmModel] = []
    public var preModelList: [AlarmModel] = []

    func modifyAlert(id: String, newValue: AlarmModel) {
        let p: AlarmModel = AlarmModel(newValue.getId(), newValue.getTitle()!, newValue.getPillCalendar()!, newValue.getAlertDateRange()!, newValue.getDayArray(), self)
        if let i = currentModelList.firstIndex(where: { el in
            el.getId() == id
        }) {
            currentModelList[i] = newValue
            currentTableView.reloadData()
        } else if let i = preModelList.firstIndex(where: { el in
            el.getId() == id
        }) {
            if(p.checkEnabled()!) {
                preModelList.remove(at: i)
                currentModelList.append(p)
                currentTableView.reloadData()
            } else {
                preModelList[i] = newValue
            }
            preTableView.reloadData()
        }

        let dayArray = p.getDayArray()
        var days_of_weeks = ""
        for (idx, p) in dayArray.enumerated() {
            days_of_weeks += p.desc
            if idx != dayArray.endIndex - 1 {
                days_of_weeks += " "
            }
        }

        let medicine_id: String = id
        let guardian_id: String = Global.shared.getPhoneNumber() // temp
        let title: String = p.getTitle()!
        let start_day: String = (p.getAlertDateRange()?.start.toDateString())!
        let end_day: String = (p.getAlertDateRange()?.end.toDateString())!
        let time: String = (p.getPillCalendar()?.toString())!
        let days_of_week: String = days_of_weeks

        let param: [String: Any] = ["medicine_id" : medicine_id, "guardian_id" : guardian_id, "title" : title, "start_day" : start_day, "end_day" : end_day, "pill_time" : time, "days_of_week" : days_of_week] as Dictionary //JSON 객체로 전송할 딕셔너리
        let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/modify_medicine")!

        InfomarkClient().post(param: param, url: url, runnable: { obj in
            let jsonObject = obj as! NSDictionary
            _ = jsonObject["state"] as? String
            _ = jsonObject["error"] as? String

            print(jsonObject)
            print("upload success!!")
        })

        PushNotificationService.registerOrModifyPillAlert(p, true);
    }
    
    func addAlert(id: String, title: String, alertTime: Date, alertDateRange: DateInterval, dayArray: [DayOfWeek], upload: Bool) {
        var days_of_weeks = ""
        for (idx, p) in dayArray.enumerated() {
            days_of_weeks += p.desc
            if idx != dayArray.endIndex - 1 {
                days_of_weeks += " "
            }
        }

        let p: AlarmModel = AlarmModel(id, title, alertTime, alertDateRange, dayArray, self)
        
        if(upload) {
            let medicine_id: String = id
            let guardian_id: String = Global.shared.getPhoneNumber() // temp
            let title: String = title
            let start_day: String = alertDateRange.start.toDateString()
            let end_day: String = alertDateRange.end.toDateString()
            let time: String = alertTime.toString()
            let days_of_week: String = days_of_weeks

            let param: [String: Any] = ["medicine_id" : medicine_id, "guardian_id" : guardian_id, "title" : title, "start_day" : start_day, "end_day" : end_day, "pill_time" : time, "days_of_week" : days_of_week] as Dictionary //JSON 객체로 전송할 딕셔너리
            let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/add_medicine")!

            InfomarkClient().post(param: param, url: url, runnable: { obj in
                let jsonObject = obj as! NSDictionary
                _ = jsonObject["state"] as? String
                _ = jsonObject["error"] as? String

                print(jsonObject)
                print("upload success!!")
            })
        }
        
        currentModelList.append(p)
        currentTableView.reloadData()
        
        PushNotificationService.registerOrModifyPillAlert(p, false)
    }
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        initData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SHOW_ALARM_SETTING_PAGE:
            if let vc = segue.destination as? AlarmSettingViewController {
                vc.mListener = self
                if let data = sender as? AlarmModel {
                    vc.alarmData = data
                }
            }
            break
            
        default:
            break
        }
        super.prepare(for: segue, sender: sender)
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .header_notice_button:
            performSegue(withIdentifier: SHOW_NOTICE_PAGE, sender: nil)
            
        case .header_setting_button:
            performSegue(withIdentifier: SHOW_SETTING_PAGE, sender: nil)
            
        case .alarm_list_add_button:
            performSegue(withIdentifier: SHOW_ALARM_SETTING_PAGE, sender: nil)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        currentTableView.register(UINib(nibName: "AlarmListCell", bundle: nil), forCellReuseIdentifier: "AlarmListCell")
        preTableView.register(UINib(nibName: "AlarmListCell", bundle: nil), forCellReuseIdentifier: "AlarmListCell")
        
//        preTableView.reloadData()
    }
    
    func initData() {
        let req_type: String = "guardian"
        let guardian_id: String = Global.shared.getPhoneNumber() // temp
        
        let param: [String: Any] = ["req_type" : req_type, "guardian_id" : guardian_id] as Dictionary //JSON 객체로 전송할 딕셔너리
        let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/get_medicine")!
        
        InfomarkClient().post(param: param, url: url, runnable: { [self] obj in
            let jsonObject = obj as! NSDictionary
            
            if let state = jsonObject["state"] as? String {
                if(state == "ok") {
                    let objCArray = NSMutableArray(object: jsonObject["list"]!)
                    if let swiftArray = objCArray as NSArray? as? [Any] {
                        for i in 0...swiftArray.count - 1 {
                            if let alertArray = swiftArray[i] as? [[String:Any]] {
                                for j in 0...alertArray.count - 1 {
                                    let alert = alertArray[j]
                                    if let days_of_week = alert["days_of_week"], let start_day = alert["start_day"], let end_day = alert["end_day"], let pill_time = alert["pill_time"], let title = alert["title"], let medicine_id = alert["medicine_id"] {
                                        let dayUtil = DayUtil()
                                        let startDate = dayUtil.parseDayString(start_day as! String)
                                        let pillTime = dayUtil.parseTimeString(pill_time as! String)
                                        let alertTime = Calendar.current.date(from: DateComponents(timeZone: TimeZone.current, year: startDate.getYear(), month: startDate.getMonth(), day: startDate.getDay(), hour: pillTime.getHour(), minute: pillTime.getMinute(), second: 0))!
                                        addAlert(id: medicine_id as! String, title: title as! String, alertTime: alertTime, alertDateRange: DateInterval(start: startDate, end: dayUtil.parseDayString(end_day as! String)), dayArray: dayUtil.parseDateArray(days_of_week as! String), upload: false)
                                    }
                                }
                            }
                        }
                    }

                    UNUserNotificationCenter.current().getPendingNotificationRequests { notiRequests in
                        print(notiRequests)
                    }
                } else if(state == "204") {
                    print("not found")
                }
            }
        })
    }
}

// MARK: - Extension
extension AlarmListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case currentTableView:
            self.currentTableViewHeight.constant = CGFloat(90 * currentModelList.count)
            self.view.layoutIfNeeded()
            return currentModelList.count
            
        case preTableView:
            self.preTableViewHeight.constant = CGFloat(90 * preModelList.count) + 80
            self.view.layoutIfNeeded()
            return preModelList.count
            
        default:
            return currentModelList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmListCell", for: indexPath) as! AlarmListCell
        
        switch tableView {
        case currentTableView:
            cell.model = currentModelList[indexPath.row]
            
        case preTableView:
            cell.model = preModelList[indexPath.row]
            
        default:
            cell.model = currentModelList[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case currentTableView:
            performSegue(withIdentifier: SHOW_ALARM_SETTING_PAGE, sender: currentModelList[indexPath.row])
            
        case preTableView:
            performSegue(withIdentifier: SHOW_ALARM_SETTING_PAGE, sender: preModelList[indexPath.row])
            
        default:
            performSegue(withIdentifier: SHOW_ALARM_SETTING_PAGE, sender: currentModelList[indexPath.row])
        }
    }
}
