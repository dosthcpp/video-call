//
//  CallStartViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/31.
//

import UIKit

class CallStartViewController: BaseViewController {
    
    fileprivate let SHOW_CALL_CONNECT_PAGE = "show_call_connect_page"
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .call_start_back_button:
            self.navigationController?.dismiss(animated: true)
            
        case .call_start_call_button:
            performSegue(withIdentifier: SHOW_CALL_CONNECT_PAGE, sender: nil)
            
        default:
            break
        }
    }
}
