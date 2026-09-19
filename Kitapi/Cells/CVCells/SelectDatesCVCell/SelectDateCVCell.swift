//
//  SelectDateCVCell.swift
//  Kitapi
//
//  Created by Suneel on 07/07/26.
//

import UIKit

class SelectDateCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var selectDateLabel: UILabel!
    
    var onSelectDateAction: (() -> Void)?
    
    static var reUseIdentifier: String {
        return String(describing: SelectDateCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: SelectDateCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setSelectDateCVCellUI()
    }
    
    @IBAction func selectDatesAction(_ sender: UIButton) {
        self.onSelectDateAction?()
    }
}

extension SelectDateCVCell {
    
    private func setSelectDateCVCellUI() {
        
        self.selectDateLabel.textAlignment = .center
        self.selectDateLabel.textColor = .textPlaceholderColor
        self.selectDateLabel.numberOfLines = 1
        self.selectDateLabel.font = UIFont(name: Fonts.urbanistRegular, size: 16)
        
        self.bgView.layer.cornerRadius = 25
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.borderColor.cgColor
    }
}
