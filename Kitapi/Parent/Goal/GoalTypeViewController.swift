//
//  GoalTypeViewController.swift
//  Kitapi
//
//  Created by Suneel on 25/08/26.
//

import UIKit

class GoalTypeViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var giftView: UIView!
    @IBOutlet weak var giftTitleLabel: UILabel!
    @IBOutlet weak var giftCheckView: UIView!
    @IBOutlet weak var giftCheckmarkImageView: UIImageView!
    
    @IBOutlet weak var milestoneView: UIView!
    @IBOutlet weak var milestoneTitleLabel: UILabel!
    @IBOutlet weak var milestoneCheckView: UIView!
    @IBOutlet weak var milestoneCheckmarkImageView: UIImageView!
    
    var didSelectGoalType: ((GoalType) -> Void)?

    static var sbIdentifier: String {
        return String(describing: GoalTypeViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGoalTypeScreenUI()
    }
    
    @objc private func giftSelected() {
        self.selectGoalType(.gift)
     }

     @objc private func milestoneSelected() {
         self.selectGoalType(.milestone)
     }
    
    private func selectGoalType(_ type: GoalType) {

        switch type {

        case .gift:
            self.giftView.backgroundColor = .gradientColor2
            self.giftCheckView.backgroundColor = .pinkPrimaryColor
            self.giftCheckmarkImageView.image = AppImages.check

            self.milestoneCheckView.backgroundColor = .buttonBorderColor
            self.milestoneCheckmarkImageView.image = nil
            self.milestoneView.backgroundColor = .white

        case .milestone:
            self.milestoneCheckView.backgroundColor = .pinkPrimaryColor
            self.milestoneCheckmarkImageView.image = AppImages.check
            self.milestoneView.backgroundColor = .gradientColor2

            
            self.giftCheckView.backgroundColor = .buttonBorderColor
            self.giftCheckmarkImageView.image = nil
            self.giftView.backgroundColor = .white
            
        default:
            break
        }

        self.didSelectGoalType?(type)
    }

}
extension GoalTypeViewController {
    
    private func setGoalTypeScreenUI() {
        
        self.headerLabel.text = APPConstants.goalTypeTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.giftTitleLabel.text = APPConstants.giftTitle
        self.giftTitleLabel.textAlignment = .center
        self.giftTitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.giftTitleLabel.textColor = .buttonTitleColor
        self.giftTitleLabel.numberOfLines = 1
        
        self.milestoneTitleLabel.text = APPConstants.mileStoneTitle
        self.milestoneTitleLabel.textAlignment = .center
        self.milestoneTitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.milestoneTitleLabel.textColor = .buttonTitleColor
        self.milestoneTitleLabel.numberOfLines = 1

        self.giftView.isUserInteractionEnabled = true
        self.giftView.layer.cornerRadius = 10
        self.giftCheckView.layer.cornerRadius = 15
        self.giftCheckView.backgroundColor = .buttonBorderColor
        
        self.milestoneView.isUserInteractionEnabled = true
        self.milestoneView.layer.cornerRadius = 10
        self.milestoneCheckView.layer.cornerRadius = 15
        self.milestoneCheckView.backgroundColor = .buttonBorderColor

        let giftTap = UITapGestureRecognizer(target: self, action: #selector(giftSelected))
        self.giftView.addGestureRecognizer(giftTap)

        let milestoneTap = UITapGestureRecognizer(target: self, action: #selector(milestoneSelected))
        self.milestoneView.addGestureRecognizer(milestoneTap)

    }
    
  
}
