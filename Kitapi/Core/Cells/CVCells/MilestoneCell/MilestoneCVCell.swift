//
//  MilestoneCVCell.swift
//  Kitapi
//
//  Created by Suneel on 30/08/26.
//

import UIKit

class MilestoneCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var milestoneCoinImageView: UIImageView!
    @IBOutlet weak var milestoneTitleLabel: UILabel!
    
    @IBOutlet weak var milestonePercentageView: UIView!
    @IBOutlet weak var milestoneProgessLabel: UILabel!

    @IBOutlet weak var milestoneProgressView: AnalyticsProgressBar!
    
    static var reUseIdentifier: String {
        return String(describing: MilestoneCVCell.self)
    }
    
    static var nibFile: UINib {
        return UINib(nibName: MilestoneCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setMilestoneCellUI()
        // Initialization code
    }

    func populateMilestoneCell(milestoneData: GoalData) {
        
        guard let milestoneAmount = milestoneData.milestoneAmount else { return }
        
        switch milestoneAmount {
            
        case 100:
            self.milestoneProgessLabel.textColor = .greenPrimaryColor
            self.milestoneProgessLabel.text = "\(Int(milestoneData.progressPercentage ?? 0))% Complete"

            self.milestoneCoinImageView.image = AppImages.hundredCoins
            self.milestoneTitleLabel.text = "100 Coins"

            self.milestoneProgressView.configureMilestoneProgress(status: .hundred, percentage: milestoneData.progressPercentage ?? 0.0)
            
        case 200:
            self.milestoneProgessLabel.textColor = .purplePrimaryColor
            self.milestoneProgessLabel.text = "\(Int(milestoneData.progressPercentage ?? 0))% Complete"

            self.milestoneCoinImageView.image = AppImages.twoHundredCoins
            self.milestoneTitleLabel.text = "200 Coins"

            self.milestoneProgressView.configureMilestoneProgress(status: .twoHundred, percentage: milestoneData.progressPercentage ?? 0.0)


        case 500:
            self.milestoneProgessLabel.textColor = .bluePrimaryColor
            self.milestoneProgessLabel.text = "\(Int(milestoneData.progressPercentage ?? 0))% Complete"

            self.milestoneCoinImageView.image = AppImages.fiveHundredCoins
            self.milestoneTitleLabel.text = "500 Coins"

            self.milestoneProgressView.configureMilestoneProgress(status: .fiveHundred, percentage: milestoneData.progressPercentage ?? 0.0)

            
        default:
            self.milestoneProgessLabel.text = ""
            self.milestoneTitleLabel.text = ""


        }
    }
}

extension MilestoneCVCell {
    
    private func setMilestoneCellUI() {
        
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.bgView.layer.cornerRadius = 12
        self.bgView.clipsToBounds = true
        
        self.milestoneProgessLabel.textAlignment = .center
        self.milestoneProgessLabel.numberOfLines = 1
        self.milestoneProgessLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.milestoneProgessLabel.text = ""
        
        self.milestoneTitleLabel.textAlignment = .left
        self.milestoneTitleLabel.numberOfLines = 1
        self.milestoneTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 16)
        self.milestoneTitleLabel.text = ""
        self.milestoneTitleLabel.textColor = .textColor

        
        self.milestonePercentageView.layer.borderWidth = 1
        self.milestonePercentageView.layer.borderColor = UIColor.gradientColor1.cgColor
        self.milestonePercentageView.layer.cornerRadius = 15
        self.milestonePercentageView.backgroundColor = .lightYellowPrimaryColor
        
    }
}
