//
//  ChoreTemplateCVCell.swift
//  Kitapi
//
//  Created by Suneel on 24/06/26.
//

import UIKit

class ChoreTemplateCVCell: UICollectionViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var templateImageView: UIImageView!
    @IBOutlet weak var choreTemplateNameLabel: UILabel!
    
    static var reUseIdentifier: String {
        return String(describing: ChoreTemplateCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: ChoreTemplateCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setChoreTemplateCellCVUI()
    }

    func populateTemplateCell(templates: TemplateData, isSelected: Bool = false) {
        self.choreTemplateNameLabel.text = templates.title
        if let url = URL(string: templates.image?.url ?? "") {
            self.templateImageView.kf.indicatorType = .activity
            self.templateImageView.kf.setImage(with: url)
        }
        
        self.bgView.layer.borderColor =  isSelected ? UIColor.pinkPrimaryColor.cgColor : UIColor.borderColor.cgColor
    }
    
    func populateDailyRecurranceCell() {
        self.choreTemplateNameLabel.text = "Chore will repeat daily"
        self.templateImageView.image = AppImages.autorenew
        self.choreTemplateNameLabel.textAlignment = .center
    }
}

extension ChoreTemplateCVCell {
    
    private func setChoreTemplateCellCVUI() {
        
        self.choreTemplateNameLabel.textAlignment = .left
        self.choreTemplateNameLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.choreTemplateNameLabel.textColor = .labelPlaceholderColor
        self.choreTemplateNameLabel.numberOfLines = 1
        
        self.bgView.layer.cornerRadius = 10
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.borderColor.cgColor
    }
    
   
}
