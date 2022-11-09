//
//  TermsViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class TermsViewController: BaseViewController {
    
    fileprivate let SHOW_TERMS_DETAIL_PAGE = "show_terms_detail_page"
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .terms_back_button:
            self.navigationController?.popViewController(animated: true)
            
        case .terms_coop_info_button:
            self.nextPrepareData = [TITLE : "사업자 정보확인"]
            performSegue(withIdentifier: SHOW_TERMS_DETAIL_PAGE, sender: nil)
            
        case .terms_service_button:
            self.nextPrepareData = [TITLE : "이용약관"]
            performSegue(withIdentifier: SHOW_TERMS_DETAIL_PAGE, sender: nil)
            
        case .terms_privacy_button:
            self.nextPrepareData = [TITLE : "개인정보 처리방침"]
            performSegue(withIdentifier: SHOW_TERMS_DETAIL_PAGE, sender: nil)
            
        default:
            break
        }
    }
}
