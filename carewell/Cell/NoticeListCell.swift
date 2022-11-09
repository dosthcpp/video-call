//
//  NoticeListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

struct NoticeModel {
    var date: String
    var title: String
    var contents: String
    var name: String
    var isGeneral: Bool
    var isNew: Bool
    
    init(_ date: String = "", _ title: String = "", _ contents: String = "", _ name: String = "", _ is_general: Bool = false, _ is_new: Bool = false) {
        self.date = date
        self.title = title
        self.contents = contents
        self.name = name
        self.isGeneral = is_general
        self.isNew = is_new
    }
}

class NoticeListCell: UITableViewCell {
    
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var typeView: UIView!
    
    @IBOutlet var newImageView: UIImageView!
    
    public var date: String {
        get {
            return dateLabel.text!
        }
        set {
            dateLabel.text = newValue
        }
    }
    public var title: String {
        get {
            return titleLabel.text!
        }
        set {
            titleLabel.text = newValue
        }
    }
    public var isGeneral: Bool {
        get {
            return false
        }
        set {
            typeLabel.text = newValue ? "일반" : "긴급"
            typeLabel.textColor = newValue ? #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1) : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
            typeView.borderColor = newValue ? #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1) : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
        }
    }
    public var isNew: Bool {
        get {
            return newImageView.isHidden
        }
        set {
            newImageView.isHidden = !newValue
        }
    }
    private var _model: NoticeModel = NoticeModel()
    public var model: NoticeModel {
        get {
            return _model
        }
        set {
            _model = newValue
            date = _model.date
            title = _model.title
            isGeneral = _model.isGeneral
            isNew = _model.isNew
        }
    }
}
