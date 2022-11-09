//
//  FriendListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/06/02.
//

import UIKit

protocol FriendListCellDelegate {
    func goToCallStart(_ index: Int)
}

struct FriendModel {
    var regNo: Int
    var name: String
    
    init(_ reg_no: Int = 0, _ name: String = "") {
        self.regNo = reg_no
        self.name = name
    }
}

class FriendListCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    
    var delegate: FriendListCellDelegate?
    
    public var name: String {
        get {
            return nameLabel.text!
        }
        set {
            nameLabel.text = newValue
        }
    }
    private var _model: FriendModel = FriendModel()
    public var model: FriendModel {
        get {
            return _model
        }
        set {
            _model = newValue
            name = _model.name
        }
    }
    
    // MARK: - IBAction
    @IBAction func onTouchCall(_ sender: UIButton) {
        delegate?.goToCallStart(-1)
    }
}
