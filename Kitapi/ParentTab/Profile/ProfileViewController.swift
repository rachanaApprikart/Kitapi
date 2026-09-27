//
//  ProfileViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
// 08-06, 28-09

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var createChildProfileButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    private let profileViewModel = ProfileViewModel()

  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setProfileScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func createChildProfileAction(_ sender: UIButton) {
        self.openCreateChildProfileVC()
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        self.logoutUser()
    }
  
    private func bindViewModel() {
        
        self.profileViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.profileViewModel.onLogoutError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.profileViewModel.onLogoutSuccess = { [weak self] logoutDetails in
            guard let self = self else { return }
            
            AppUserDefaults.authorizationToken = nil
            AppUserDefaults.customerDetails = nil
            AppUserDefaults.childModeExpiryDate = nil
            AppUserDefaults.isChildMode = false
            self.navigateToLogin()
        }
 
    }
    
    private func logoutUser() {
        Task {
            await self.profileViewModel.performLogout()
        }
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
        self.hideActivityIndicator()
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
    
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicatorView.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.activityIndicatorView.stopAnimating()
        self.view.sendSubviewToBack(self.activityView)
    }
}

