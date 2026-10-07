//
//  ActionSheetViewController.swift
//  Kitapi
//
//  Created by Suneel on 05/10/26.
//

import UIKit

class ActionSheetViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    
    var actionSheetType: ActionSheetType = .account
    var childDetails: Child?
    
    weak var accountDelegate: AccountActionSheetDelegate?
    weak var childProfileDelegate: ChildProfileActionSheetDelegate?
    
    static var sbIdentifier: String {
        return String(describing: ActionSheetViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setActionSheeyScreenUI()
        self.configureUI()
    }
    
    
    private func configureUI() {
        
        switch actionSheetType {
            
        case .account:
            self.titleLabel.text = "Account Settings"
            self.firstButton.setTitle("Logout Account", for: .normal)
            self.secondButton.setTitle("Delete Account", for: .normal)
            
        case .childProfile:
            self.titleLabel.text = "Child Profile"
            self.firstButton.setTitle("Edit Account", for: .normal)
            self.secondButton.setTitle("Delete Account", for: .normal)
        }
    }
    
    @IBAction func firstButtonAction(_ sender: UIButton) {
        
        switch actionSheetType {
            
        case .account:
            self.showLogoutConfirmation()
            
        case .childProfile:
            self.childProfileDelegate?.didTapEditChild(details: self.childDetails)
        }
    }
    
    
    @IBAction func secondButtonAction(_ sender: UIButton) {
        
        switch actionSheetType {
            
        case .account:
            self.showDeleteAccountConfirmation()
            
        case .childProfile:
            self.showDeleteChildConfirmation()
        }
    }
    
    private func showLogoutConfirmation() {
        
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(title: "No", style: .cancel)
        )
        
        alert.addAction(
            UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                self?.accountDelegate?.didTapLogout()
            }
        )
        self.present(alert, animated: true)
    }
    
    private func showDeleteAccountConfirmation() {
        
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account?",
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(title: "No", style: .cancel)
        )
        
        alert.addAction(
            UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                self?.accountDelegate?.didTapDeleteAccount()
                self?.dismiss(animated: true)
            }
        )
        
        present(alert, animated: true)
    }
    
    private func showDeleteChildConfirmation() {
        
        let alert = UIAlertController(
            title: "Delete Child",
            message: "Are you sure you want to delete this child profile?",
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(title: "No", style: .cancel)
        )
        
        alert.addAction(
            UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                self?.childProfileDelegate?.didTapDeleteChild()
                self?.dismiss(animated: true)
            }
        )
        
        present(alert, animated: true)
    }
}

extension ActionSheetViewController {
    
    private func setActionSheeyScreenUI() {
                        
        self.titleLabel.textAlignment = .center
        self.titleLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.titleLabel.textColor = .headerLabekColor
        self.titleLabel.numberOfLines = 1
        
        self.firstButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 15)
        self.firstButton.setTitleColor(.headerLabekColor, for: .normal)
        self.firstButton.layer.cornerRadius = 25
        self.firstButton.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.firstButton.layer.borderWidth = 1
        
        self.secondButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 15)
        self.secondButton.setTitleColor(.redPrimaryColor, for: .normal)
        self.secondButton.layer.cornerRadius = 25
        self.secondButton.layer.borderColor = UIColor.redPrimaryColor.cgColor
        self.secondButton.layer.borderWidth = 1
    }
}


enum ActionSheetType {
    case account
    case childProfile
}
protocol AccountActionSheetDelegate: AnyObject {
    func didTapLogout()
    func didTapDeleteAccount()
}

protocol ChildProfileActionSheetDelegate: AnyObject {
    func didTapEditChild(details: Child?)
    func didTapDeleteChild()
}
