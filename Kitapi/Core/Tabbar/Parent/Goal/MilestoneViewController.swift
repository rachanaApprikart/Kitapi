//
//  MilestoneViewController.swift
//  Kitapi
//
//  Created by Suneel on 25/08/26.
// 26 Aug

import UIKit

class MilestoneViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var hundredCoinsView: UIView!
    @IBOutlet weak var hundredCoinsTitleLabel: UILabel!
    @IBOutlet weak var hundredCoinsCheckView: UIView!
    @IBOutlet weak var hundredCoinsCheckmarkImageView: UIImageView!
    
    @IBOutlet weak var twoHundredCoinsView: UIView!
    @IBOutlet weak var twoHundredCoinsTitleLabel: UILabel!
    @IBOutlet weak var twoHundredCoinsCheckView: UIView!
    @IBOutlet weak var twoHundredCoinsCheckmarkImageView: UIImageView!

    @IBOutlet weak var fiveHundredCoinsView: UIView!
    @IBOutlet weak var fiveHundredCoinsTitleLabel: UILabel!
    @IBOutlet weak var fiveHundredCoinsCheckView: UIView!
    @IBOutlet weak var fiveHundredCoinsCheckmarkImageView: UIImageView!

    static var sbIdentifier: String {
        return String(describing: MilestoneViewController.self)
    }
    
    var didSelectMilestone: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setMilestoneScreenUI()
        // Do any additional setup after loading the view.
    }
    
    @objc private func hundredCoinsSelected() {
        self.selectAmount(100)
     }

     @objc private func twoHundredCoinsSelected() {
         self.selectAmount(200)
     }
    
    @objc private func fiveHundredCoinsSelected() {
        self.selectAmount(500)
    }
    
    private func selectAmount(_ amount: Int) {
        
        switch amount {
            
        case 100:
            
            self.hundredCoinsView.backgroundColor = .gradientColor2
            self.hundredCoinsCheckView.backgroundColor = .pinkPrimaryColor
            self.hundredCoinsCheckmarkImageView.image = AppImages.check
            
            self.hundredCoinsView.backgroundColor = .white
            self.twoHundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.twoHundredCoinsCheckmarkImageView.image = nil
            
            self.fiveHundredCoinsView.backgroundColor = .white
            self.fiveHundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.fiveHundredCoinsCheckmarkImageView.image = nil
            
        case 200:
            
            self.hundredCoinsView.backgroundColor = .white
            self.hundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.hundredCoinsCheckmarkImageView.image = nil
            
            self.hundredCoinsView.backgroundColor = .gradientColor2
            self.twoHundredCoinsCheckView.backgroundColor = .pinkPrimaryColor
            self.twoHundredCoinsCheckmarkImageView.image = AppImages.check
            
            self.fiveHundredCoinsView.backgroundColor = .white
            self.fiveHundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.fiveHundredCoinsCheckmarkImageView.image = nil
            
        case 500:
            
            self.hundredCoinsView.backgroundColor = .white
            self.hundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.hundredCoinsCheckmarkImageView.image = nil
            
            self.hundredCoinsView.backgroundColor = .white
            self.twoHundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.twoHundredCoinsCheckmarkImageView.image = nil
            
            self.fiveHundredCoinsView.backgroundColor = .gradientColor2
            self.fiveHundredCoinsCheckView.backgroundColor = .pinkPrimaryColor
            self.fiveHundredCoinsCheckmarkImageView.image = AppImages.check
            
        default:
            
            self.hundredCoinsView.backgroundColor = .white
            self.hundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.hundredCoinsCheckmarkImageView.image = nil
            
            self.hundredCoinsView.backgroundColor = .white
            self.twoHundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.twoHundredCoinsCheckmarkImageView.image = nil
            
            self.fiveHundredCoinsView.backgroundColor = .white
            self.fiveHundredCoinsCheckView.backgroundColor = .buttonBorderColor
            self.fiveHundredCoinsCheckmarkImageView.image = nil
            
        }
        self.didSelectMilestone?(amount)
    }
}

extension MilestoneViewController {
    
    private func setMilestoneScreenUI() {
        
        self.headerLabel.text = APPConstants.milestonePlaceholder
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.hundredCoinsTitleLabel.text = "100 Coins"
        self.hundredCoinsTitleLabel.textAlignment = .center
        self.hundredCoinsTitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.hundredCoinsTitleLabel.textColor = .buttonTitleColor
        self.hundredCoinsTitleLabel.numberOfLines = 1
        
        self.twoHundredCoinsTitleLabel.text = "200 Coins"
        self.twoHundredCoinsTitleLabel.textAlignment = .center
        self.twoHundredCoinsTitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.twoHundredCoinsTitleLabel.textColor = .buttonTitleColor
        self.twoHundredCoinsTitleLabel.numberOfLines = 1

        self.fiveHundredCoinsTitleLabel.text = "500 Coins"
        self.fiveHundredCoinsTitleLabel.textAlignment = .center
        self.fiveHundredCoinsTitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.fiveHundredCoinsTitleLabel.textColor = .buttonTitleColor
        self.fiveHundredCoinsTitleLabel.numberOfLines = 1
        
        self.hundredCoinsView.isUserInteractionEnabled = true
        self.hundredCoinsView.layer.cornerRadius = 10
        self.hundredCoinsCheckView.layer.cornerRadius = 15
        self.hundredCoinsCheckView.backgroundColor = .buttonBorderColor
        
        self.twoHundredCoinsView.isUserInteractionEnabled = true
        self.twoHundredCoinsView.layer.cornerRadius = 10
        self.twoHundredCoinsCheckView.layer.cornerRadius = 15
        self.twoHundredCoinsCheckView.backgroundColor = .buttonBorderColor

        self.fiveHundredCoinsView.isUserInteractionEnabled = true
        self.fiveHundredCoinsView.layer.cornerRadius = 10
        self.fiveHundredCoinsCheckView.layer.cornerRadius = 15
        self.fiveHundredCoinsCheckView.backgroundColor = .buttonBorderColor
        
        let hCoinap = UITapGestureRecognizer(target: self, action: #selector(hundredCoinsSelected))
        self.hundredCoinsView.addGestureRecognizer(hCoinap)

        let twoHTap = UITapGestureRecognizer(target: self, action: #selector(twoHundredCoinsSelected))
        self.twoHundredCoinsView.addGestureRecognizer(twoHTap)
        
        let fiveHTap = UITapGestureRecognizer(target: self, action: #selector(fiveHundredCoinsSelected))
        self.fiveHundredCoinsView.addGestureRecognizer(fiveHTap)

    }
    
  
}
