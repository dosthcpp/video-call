//
//  CallListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/06/02.
//

import UIKit

protocol CallListCellDelegate {
    func onTapCall()
    func onTapSafetyCall()
}

struct CallModel {
    var name: String
    var number: String
    
    init(_ name: String = "", _ number: String = "") {
        self.name = name
        self.number = number
    }
}

class CallListCell: UITableViewCell {
    
    @IBOutlet var iconTop: NSLayoutConstraint!
    @IBOutlet var iconBottom: NSLayoutConstraint!
    @IBOutlet var name: UILabel!
    @IBOutlet var number: UILabel!

    @IBOutlet var safety_call: UIButton!
    @IBOutlet var call: UIButton!

    @IBOutlet var icons: UIStackView!
    
    @IBOutlet var status: UIImageView!
    @IBOutlet var background: UIImageView!
    
    var delegate: CallListCellDelegate?
    var isTouched = false
    public var nameString: String {
        get {
            return name.text!
        }
        set {
            name.text = newValue
            name.sizeToFit()
        }
    }
    public var numberString: String {
        get {
            return number.text!
        }
        set {
            number.text = newValue
            number.sizeToFit()
        }
    }
    public var buttons: UIStackView {
        get {
            return icons
        }
    }

    private var _model: CallModel = CallModel()
    public var model: CallModel {
        get {
            return _model
        }
        set {
            _model = newValue
            nameString = _model.name
            numberString = _model.number
            buttons.isHidden = true
        }
    }
    
    
    @IBAction func onTapSafetyCall(_ sender: Any) {
        delegate?.onTapSafetyCall()
    }
    
    
    @IBAction func onTapCall(_ sender: Any) {
        delegate?.onTapCall()
    }
}
