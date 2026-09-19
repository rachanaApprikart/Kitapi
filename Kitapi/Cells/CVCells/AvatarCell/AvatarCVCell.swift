//
//  AvatarCVCell.swift
//  Kitapi
//
//  Created by Suneel on 15/05/26.
//

import UIKit

class AvatarCVCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var selectProfileView: UIView!
    
    private var currentMilestones: [GoalData] = []

    static var reUseIdentifier: String {
        return String(describing: AvatarCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: AvatarCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setAvatarCellUI()
    }
    
    func populateAvatarCell(items: UIImage, isSelected: Bool = false) {
        self.avatarImageView.image = items
       
        
        self.selectProfileView.isHidden = !isSelected
        self.bgView.layer.borderWidth = isSelected ? 2 : 0
        self.bgView.layer.borderColor =  isSelected ? UIColor.pinkPrimaryColor.cgColor : UIColor.white.cgColor
        
    }
    
    func populateMilestoneCell(milestoneData: GoalData) {
        self.selectProfileView.isHidden = true
        self.bgView.backgroundColor = .clear
       

        switch milestoneData.milestoneAmount {
            
        case 100:
            
            self.avatarImageView.image = AppImages.hundredCoins
            
        case 200:
            
            self.avatarImageView.image = AppImages.twoHundredCoins
            
            
        case 500:
            
            self.avatarImageView.image = AppImages.fiveHundredCoins
            
            
        default:
            
            self.avatarImageView.image = nil
            
        }
    }
    
    private func setAvatarCellUI() {
        self.bgView.layer.cornerRadius = 36
        self.selectProfileView.backgroundColor = .pinkPrimaryColor
        self.selectProfileView.layer.cornerRadius = 12.5
    }
}
