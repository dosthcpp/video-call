//
//  SettingViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit

class SettingViewController: BaseViewController {
    
    @IBOutlet var versionLabel: UILabel!
    
    fileprivate let SHOW_MODIFY_PW_PAGE = "show_modify_pw_page"
    fileprivate let SHOW_CLIENT_CENTER_PAGE = "show_client_center_page"
    fileprivate let SHOW_TERMS_PAGE = "show_terms_page"
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .setting_back_button:
            self.navigationController?.dismiss(animated: true)
            
        case .setting_modify_pw_button:
            performSegue(withIdentifier: SHOW_MODIFY_PW_PAGE, sender: nil)
            
        case .setting_client_center_button:
            performSegue(withIdentifier: SHOW_CLIENT_CENTER_PAGE, sender: nil)
            
        case .setting_terms_button:
            performSegue(withIdentifier: SHOW_TERMS_PAGE, sender: nil)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        versionLabel.text = "Ver \(CommonUtil().getCurrentVersion())"
    }
}
