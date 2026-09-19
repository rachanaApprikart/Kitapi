//
//  ChildListTVCell.swift
//  Kitapi
//
//  Created by Suneel on 31/05/26.
//

import UIKit

class ChildListTVCell: UITableViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var childProfileImageView: UIImageView!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var childNameLabel: UILabel!
    
    
    static var reUseIdentifier: String {
        return String(describing: ChildListTVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: ChildListTVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setChildListUI()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
       func populateCell(with child: Child, isSelected: Bool) {
           self.childNameLabel.text = child.name
           if let url = URL(string: child.profilePicture?.url ?? "") {
               self.childProfileImageView.kf.setImage(with: url)
           }
           self.checkMarkView.backgroundColor = isSelected ? .labelPlaceholderColor : .white
           self.bgView.backgroundColor = isSelected ? .gradientColor3 : .clear
       }
    
}



extension ChildListTVCell {
    
    private func setChildListUI() {
        self.selectionStyle = .none
        
        self.childNameLabel.textColor = .textColor
        self.childNameLabel.textAlignment = .left
        self.childNameLabel.numberOfLines = 1
        self.childNameLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        
        self.checkMarkView.backgroundColor = .labelPlaceholderColor
        self.checkMarkView.layer.cornerRadius = 12.5
    }
}
