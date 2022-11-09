//
//  CallConnectViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/06/02.
//

import UIKit

class CallConnectViewController: BaseViewController {
    
    @IBOutlet var guideLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var retryView: UIView!
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .call_connect_cancel_button:
            updateView(false)
            
        case .call_connect_exit_button:
            self.navigationController?.dismiss(animated: true)
            
        case .call_connect_retry_button:
            updateView(true)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func updateView(_ isConnecting: Bool) {
        cancelButton.isHidden = !isConnecting
        retryView.isHidden = isConnecting
        guideLabel.text = isConnecting ? "영상통화\n연결 중입니다." : "영상통화\n연결이 되지 않습니다."
    }
}
