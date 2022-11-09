//
//  CallAddViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/06/02.
//

import UIKit

class CallAddViewController: BaseViewController {
    
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var timeButton: UIButton!
    @IBOutlet var personButton: UIButton!
    @IBOutlet var confirmButton: UIButton!
    
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var personLabel: UILabel!
    
    fileprivate let SHOW_TIME_SETTING_PAGE = "show_time_setting_page"
    fileprivate let SHOW_JOIN_SETTING_PAGE = "show_join_setting_page"
    
    private var resultTime: String = ""
    private var resultPerson: String = ""
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SHOW_TIME_SETTING_PAGE:
            if let vc = segue.destination as? TimeSettingViewController {
                vc.delegate = self
            }
            break
            
        case SHOW_JOIN_SETTING_PAGE:
            if let vc = segue.destination as? JoinSettingViewController {
                vc.delegate = self
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
        case .call_add_cancel_button:
            self.dismiss(animated: true)
            
        case .call_add_delete_button:
            showCancelPopup()
            
        case .call_add_time_button:
            performSegue(withIdentifier: SHOW_TIME_SETTING_PAGE, sender: nil)
            
        case .call_add_person_button:
            performSegue(withIdentifier: SHOW_JOIN_SETTING_PAGE, sender: nil)
            
        case .call_add_confirm_button:
            // TODO: add call list API
            self.dismiss(animated: true)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func updateView() {
        timeLabel.textColor = resultTime.isEmpty ? #colorLiteral(red: 0.8901960784, green: 0.8901960784, blue: 0.8901960784, alpha: 1) : #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1)
        personLabel.textColor = resultPerson.isEmpty ? #colorLiteral(red: 0.8901960784, green: 0.8901960784, blue: 0.8901960784, alpha: 1) : #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1)
        
        timeButton.isSelected = !resultTime.isEmpty
        timeButton.layer.borderColor = resultTime.isEmpty ? #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1) : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
        personButton.isSelected = !resultPerson.isEmpty
        personButton.layer.borderColor = resultPerson.isEmpty ? #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1) : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
        
        deleteButton.isHidden = resultTime.isEmpty || resultPerson.isEmpty
        confirmButton.isHidden = resultTime.isEmpty || resultPerson.isEmpty
    }
    
    func showCancelPopup() {
        if let cancelPopup = UINib(nibName: "CancelPopup", bundle: nil).instantiate(withOwner: self, options: nil).first as? CancelPopup {
            guard let bounds = UIApplication.shared.windows.first?.bounds else { return }
            cancelPopup.delegate = self
            cancelPopup.frame = bounds
            cancelPopup.initView("영상통화 리스트를 삭제하시겠습니까?")
            UIApplication.shared.windows.first?.addSubview(cancelPopup)
        }
    }
}

// MARK: - Extension TimeSettingViewDelegate
extension CallAddViewController: TimeSettingViewDelegate {
    func setSelectedTime(_ time: String) {
        resultTime = time
        timeLabel.text = resultTime
        
        updateView()
    }
}
// MARK: - Extension JoinSettingViewDelegate
extension CallAddViewController: JoinSettingViewDelegate {
    func setSelectedPerson(_ name: String) {
        resultPerson = name
        personLabel.text = resultPerson
        
        updateView()
    }
}
// MARK: - Extension CancelPopupDelegate
extension CallAddViewController: CancelPopupDelegate {
    func didCompleted() {
        self.dismiss(animated: true)
    }
}
