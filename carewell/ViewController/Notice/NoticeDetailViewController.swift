//
//  NoticeDetailViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/31.
//

import UIKit

class NoticeDetailViewController: BaseViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    
    @IBOutlet var typeView: UIView!
    
    @IBOutlet var newImageView: UIImageView!
    
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - function
    func initView() {
        guard let data = preparedData?[DATA] as? NoticeModel else { return }
        
        titleLabel.text = data.title
        dateLabel.text = data.date
        nameLabel.text = data.name
        contentLabel.text = data.contents
        typeLabel.text = data.isGeneral ? "일반" : "긴급"
        typeLabel.textColor = data.isGeneral ? #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1) : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
        typeView.borderColor = data.isGeneral ? #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1) : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
        newImageView.isHidden = !data.isNew
    }
}
