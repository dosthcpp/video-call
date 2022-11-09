//
//  idListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit

struct AccountModel {
    var id: String
    var date: String
    
    init(_ id: String = "", _ date: String = "") {
        self.id = id
        self.date = date
    }
}

class AccountListCell: UITableViewCell {
    
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    public var id: String {
        get {
            return idLabel.text!
        }
        set {
            idLabel.text = newValue
        }
    }
    public var date: String {
        get {
            return dateLabel.text!
        }
        set {
            dateLabel.text = "\(newValue) 가입"
        }
    }
    private var _model: AccountModel = AccountModel()
    public var model: AccountModel {
        get {
            return _model
        }
        set {
            _model = newValue
            id = _model.id
            date = _model.date
        }
    }
}
