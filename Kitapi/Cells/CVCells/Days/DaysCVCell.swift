//
//  DaysCVCell.swift
//  Kitapi
//
//  Created by Suneel on 08/07/26.
//

import UIKit

class DaysCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var daysLabel: UILabel!
    
    static var reUseIdentifier: String {
        return String(describing: DaysCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: DaysCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setDaysCVCellUI()
        // Initialization code
    }

    func configure(title: String, isSelected: Bool, isEnabled: Bool) {

        self.daysLabel.text = title

        self.bgView.alpha = isEnabled ? 1 : 0.4
        self.bgView.isUserInteractionEnabled = isEnabled

        if isSelected {

            self.bgView.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
            self.daysLabel.textColor = .pinkPrimaryColor

        } else {

            self.bgView.layer.borderColor = UIColor.clear.cgColor
            self.daysLabel.textColor = .textColor
        }
    }
    
    func configure(with item: WeekDay) {

        self.daysLabel.text = item.name
        
        self.bgView.alpha = item.isEnabled ? 1 : 0.4
        self.bgView.isUserInteractionEnabled = item.isEnabled ? true : false
        
        self.daysLabel.textColor = item.isSelected ? .pinkPrimaryColor : UIColor.textColor
        self.bgView.layer.borderColor =  item.isSelected ? UIColor.pinkPrimaryColor.cgColor : UIColor.borderColor.cgColor
    }
}

extension DaysCVCell {
    
    private func setDaysCVCellUI() {
        
        self.daysLabel.textAlignment = .center
        self.daysLabel.textColor = .textColor
        self.daysLabel.numberOfLines = 1
        self.daysLabel.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        self.bgView.layer.cornerRadius = 12
       
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.borderColor.cgColor
    }
}
