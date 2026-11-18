//
//  ChoreStatusCVCell.swift
//  Kitapi
//
//  Created by Suneel on 17/11/26.
//

import UIKit

class ChoreStatusCVCell: UICollectionViewCell {
    
    @IBOutlet weak var contentBGView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    
    static var reUseIdentifier: String {
        return String(describing: ChoreStatusCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: ChoreStatusCVCell.reUseIdentifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setStatusCVCellUI()
        // Initialization code
    }
    
    func configureStatusFilter(title: String, isSelected: Bool) {

        self.statusLabel.text = title

        if isSelected {
            self.bgView.backgroundColor = .buttonBackgroundColor
            self.statusLabel.textColor = .white
            self.contentBGView.backgroundColor = .gradientColor1
        } else {
            self.bgView.backgroundColor = .gradientColor1
            self.statusLabel.textColor = .textColor
            self.contentBGView.backgroundColor = .white
        }
    }

}


extension ChoreStatusCVCell {
    
    private func setStatusCVCellUI() {
        
        self.statusLabel.textAlignment = .center
        self.statusLabel.textColor = .textColor
        self.statusLabel.numberOfLines = 1
        self.statusLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 14)
        
        self.contentBGView.layer.cornerRadius = 10
        self.bgView.layer.cornerRadius = 7

    }
}
