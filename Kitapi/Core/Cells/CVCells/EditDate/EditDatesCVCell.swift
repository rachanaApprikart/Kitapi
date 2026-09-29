//
//  EditDatesCVCell.swift
//  Kitapi
//
//  Created by Suneel on 16/07/26.
//

import UIKit

class EditDatesCVCell: UICollectionViewCell {
    
    static var reUseIdentifier: String {
        return String(describing: EditDatesCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: EditDatesCVCell.reUseIdentifier, bundle: nil)
    }
    
    var onEditDateAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func editDatesAction(_ sender: UIButton) {
        self.onEditDateAction?()
    }
}
