//
//  TermsOfServiceViewController.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/25.
//

import Foundation
import UIKit

class TermsOfServiceViewController: BaseViewController {

    @IBOutlet public var content: UITextView!
    public var contentString: NSAttributedString?
    
    @IBAction func onBackBtn(_ sender: UIButton) {
    }

    override func viewDidAppear(_ animated: Bool) {
        if let contentString = contentString {
            content.attributedText = contentString
        }
    }
}
