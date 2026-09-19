//
//  CurrentSelectionCVCell.swift
//  Kitapi
//
//  Created by Suneel on 01/07/26.
//

import UIKit

class CurrentSelectionCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var selectedIconImageView: UIImageView!
    @IBOutlet weak var createdChoreLabel: UILabel!
     
    @IBOutlet weak var removeButton: UIButton!
    var onRemoveButtonTapped: (() -> Void)?
    
    
    static var reUseIdentifier: String {
        return String(describing: CurrentSelectionCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: CurrentSelectionCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setCurrentSelectionCellUI()
    }

    @IBAction func removeChoreAction(_ sender: UIButton) {
        self.onRemoveButtonTapped?()
    }
    
    func populateCurrentSelectionCell(templates: TemplateData) {
        self.onRemoveButtonTapped = nil

        self.createdChoreLabel.text = templates.title
       // self.removeButton.setTitle("Remove", for: .normal)
        
        if let url = URL(string: templates.image?.url ?? "") {
            self.selectedIconImageView.kf.indicatorType = .activity
            self.selectedIconImageView.kf.setImage(with: url)
        }
    }
}

extension CurrentSelectionCVCell {
    
    private func setCurrentSelectionCellUI() {
        
        self.createdChoreLabel.textAlignment = .left
        self.createdChoreLabel.textColor = .labelPlaceholderColor
        self.createdChoreLabel.numberOfLines = 1
        
        self.bgView.layer.cornerRadius = 10
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.lightGreyColor.cgColor
        
        self.removeButton.setTitle("", for: .normal)
    }
}
