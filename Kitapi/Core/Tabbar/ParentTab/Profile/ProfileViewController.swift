//
//  ProfileViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
// 08-06

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var createChildProfileButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setProfileScreenUI()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.tabBarController?.tabBar.isHidden = false
//    }
    
    @IBAction func createChildProfileAction(_ sender: UIButton) {
        self.openCreateChildProfileVC()
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        AppUserDefaults.authorizationToken = nil
        AppUserDefaults.customerDetails = nil
        self.navigateToLogin()
    }
  
    
    private func openCreateChildProfileVC() {
        guard let vc = VCManager.openCreateChildProfileVC() else { return }
        vc.hidesBottomBarWhenPushed = true
        vc.IS_COMING_FROM_PROFILE_SCREEN = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    fileprivate func navigateToLogin() {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
              let vc = VCManager.openLoginVC() else {
            return
        }
        let navVC = UINavigationController(rootViewController: vc)
        navVC.setNavigationBarHidden(true, animated: true)
        sceneDelegate.window?.rootViewController = navVC
    }
}

//MARK: ---------- ui ---------

extension ProfileViewController {
    
    private func setProfileScreenUI() {
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = "Profile"
        self.headerLabel.textAlignment = .left
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.logoutButton.setTitle("Logout", for: .normal)
        self.logoutButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.logoutButton.setTitleColor(.headerLabekColor, for: .normal)
        self.logoutButton.layer.cornerRadius = 15
        self.logoutButton.layer.borderColor = UIColor.borderColor.cgColor
        self.logoutButton.layer.borderWidth = 1
        
        self.createChildProfileButton.setTitle(APPConstants.createChidAcc, for: .normal)
        self.createChildProfileButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.createChildProfileButton.setTitleColor(.headerLabekColor, for: .normal)
        self.createChildProfileButton.layer.cornerRadius = 15
        self.createChildProfileButton.layer.borderColor = UIColor.borderColor.cgColor
        self.createChildProfileButton.layer.borderWidth = 1
        
    }
}

