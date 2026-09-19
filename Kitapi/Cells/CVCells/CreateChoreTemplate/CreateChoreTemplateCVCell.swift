//
//  CreateChoreTemplateCVCell.swift
//  Kitapi
//
//  Created by Suneel on 26/06/26.
//

import UIKit

class CreateChoreTemplateCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var createChoreTemplateLabel: UILabel!
    @IBOutlet weak var createChoreTemplateButton: UIButton!
    
    var onCreateChoreTemplateAction: (() -> Void)?
    
    static var reUseIdentifier: String {
        return String(describing: CreateChoreTemplateCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: CreateChoreTemplateCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setCreateChoreTemplateCellCVUI()
        // Initialization code
    }

    @IBAction func createChoreTemplateAction(_ sender: UIButton) {
        self.onCreateChoreTemplateAction?()
    }
    
    func populateAssignChoreCell(data: GoalData) {
        
        self.createChoreTemplateLabel.text = data.title
        self.createChoreTemplateLabel.font = UIFont(name: Fonts.urbanistBold, size: 16)
        self.createChoreTemplateButton.setTitle(APPConstants.assignChores, for: .normal)
        
    }
}

extension CreateChoreTemplateCVCell {
    
    private func setCreateChoreTemplateCellCVUI() {
        
        self.createChoreTemplateLabel.textAlignment = .left
        self.createChoreTemplateLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.createChoreTemplateLabel.textColor = .labelPlaceholderColor
        self.createChoreTemplateLabel.numberOfLines = 1
        
        self.bgView.layer.cornerRadius = 15
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        
        self.createChoreTemplateButton.setTitle("Create a new chore", for: .normal)
        self.createChoreTemplateButton.titleLabel?.font = UIFont(name: Fonts.urbanistExtraBold, size: 14)
        self.createChoreTemplateButton.setTitleColor(.pinkPrimaryColor, for: .normal)
        self.createChoreTemplateButton.backgroundColor = .white
        self.createChoreTemplateButton.layer.cornerRadius = 17.5
        self.createChoreTemplateButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.createChoreTemplateButton.layer.borderWidth = 1
    }
    
   
}
