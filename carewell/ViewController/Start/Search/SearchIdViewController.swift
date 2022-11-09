//
//  SearchIdViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/26.
//

import UIKit

protocol SearchIdViewDelegate: class {
    func didSelectedPw()
}

class SearchIdViewController: BaseViewController {
    
    fileprivate let SHOW_RESULT_ID_PAGE = "show_result_id_page"
    weak var delegate: SearchIdViewDelegate?
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchConfirm(_ sender: UIButton) {
        self.nextPrepareData = [DELEGATE : self]
        performSegue(withIdentifier: SHOW_RESULT_ID_PAGE, sender: nil)
    }
    
    // MARK: - function
    func initView() {
        
    }
}

// MARK: - Extension ResultIdViewDelegate
extension SearchIdViewController: ResultIdViewDelegate {
    func goToResetPw() {
        delegate?.didSelectedPw()
    }
}
