//
//  MissedListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/05/31.
//

import UIKit

struct MissedModelList {
    var date: String
    var data: [MissedModel]
}

struct MissedModel {
    var name: String
    var time: String
    
    init(_ name: String = "", _ time: String = "") {
        self.name = name
        self.time = time
    }
}

class MissedListCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    public var name: String {
        get {
            return nameLabel.text!
        }
        set {
            nameLabel.text = newValue
        }
    }
    public var time: String {
        get {
            return timeLabel.text!
        }
        set {
            timeLabel.text = newValue
        }
    }
    private var _model: MissedModel = MissedModel()
    public var model: MissedModel {
        get {
            return _model
        }
        set {
            _model = newValue
            name = _model.name
            time = _model.time
        }
    }
}
