//
//  ProfileViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
// 08-06, 28-09

import UIKit
import FloatingPanel

class ProfileViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var editParentProfile: UIButton!
    @IBOutlet weak var changeMPINButton: UIButton!
    @IBOutlet weak var viewAllChildren: UIButton!
    @IBOutlet weak var createChildProfileButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    private let profileViewModel = ProfileViewModel()
    private var floatingPanel: FloatingPanelController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setProfileScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func editParentProfileAction(_ sender: UIButton) {
        self.openEditParentProfileVC()
    }
    
    @IBAction func createChildProfileAction(_ sender: UIButton) {
        self.openCreateChildProfileVC()
    }
    
    @IBAction func changeMPINAction(_ sender: UIButton) {
        self.showChangeMPINVC()
    }
    
    @IBAction func viewAllChildrenAction(_ sender: UIButton) {
        self.openViewAlleChildProfilseVC()
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        self.showActionSheetVC()
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
            ChildManager.shared.clearChildMode()
            self.navigateToLogin()
        }
        
        self.profileViewModel.onDeleteUserError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.profileViewModel.onDeleteUserSuccess = { [weak self] logoutDetails in
            guard let self = self else { return }
            
            AppUserDefaults.authorizationToken = nil
            AppUserDefaults.customerDetails = nil
            ChildManager.shared.clearChildMode()
            self.navigateToLogin()
        }
    }
    
    private func logoutUser() {
        Task {
            await self.profileViewModel.performLogout()
        }
    }
    
    private func deleteUser() {
        Task {
            await self.profileViewModel.deleteUser()
        }
    }
    
    private func openCreateChildProfileVC() {
        guard let vc = VCManager.openCreateChildProfileVC() else { return }
        vc.hidesBottomBarWhenPushed = true
        vc.IS_COMING_FROM_PROFILE_SCREEN = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openViewAlleChildProfilseVC() {
        guard let vc = VCManager.openViewAllChildProfilesVC() else { return }
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openEditParentProfileVC() {
        guard let vc = VCManager.openEditParentDetailsVC() else { return }
        vc.hidesBottomBarWhenPushed = true
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

extension ProfileViewController: UpdateMPINDelegate, AccountActionSheetDelegate {
    
    func didTapLogout() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.logoutUser()
    }
    
    func didTapDeleteAccount() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.deleteUser()
    }
    
    
    func mpinChangedSuccessfully() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
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
        
        self.logoutButton.setTitle("Account", for: .normal)
        self.logoutButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.logoutButton.setTitleColor(.headerLabekColor, for: .normal)
        self.logoutButton.layer.cornerRadius = 15
        self.logoutButton.layer.borderColor = UIColor.borderColor.cgColor
        self.logoutButton.layer.borderWidth = 1
        
        self.editParentProfile.setTitle("Edit Parent Profile", for: .normal)
        self.editParentProfile.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.editParentProfile.setTitleColor(.headerLabekColor, for: .normal)
        self.editParentProfile.layer.cornerRadius = 15
        self.editParentProfile.layer.borderColor = UIColor.borderColor.cgColor
        self.editParentProfile.layer.borderWidth = 1
        
        self.changeMPINButton.setTitle("Change MPIN", for: .normal)
        self.changeMPINButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.changeMPINButton.setTitleColor(.headerLabekColor, for: .normal)
        self.changeMPINButton.layer.cornerRadius = 15
        self.changeMPINButton.layer.borderColor = UIColor.borderColor.cgColor
        self.changeMPINButton.layer.borderWidth = 1
        
        self.viewAllChildren.setTitle("View Child Profiles", for: .normal)
        self.viewAllChildren.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.viewAllChildren.setTitleColor(.headerLabekColor, for: .normal)
        self.viewAllChildren.layer.cornerRadius = 15
        self.viewAllChildren.layer.borderColor = UIColor.borderColor.cgColor
        self.viewAllChildren.layer.borderWidth = 1
        
        self.createChildProfileButton.setTitle(APPConstants.createChidAcc, for: .normal)
        self.createChildProfileButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 18)
        self.createChildProfileButton.setTitleColor(.headerLabekColor, for: .normal)
        self.createChildProfileButton.layer.cornerRadius = 15
        self.createChildProfileButton.layer.borderColor = UIColor.borderColor.cgColor
        self.createChildProfileButton.layer.borderWidth = 1
        
    }
    
    private func showChangeMPINVC() {
        guard let contentVC = VCManager.openUpdateMPINVC() else { return }
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.55)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showActionSheetVC() {
        guard let contentVC = VCManager.openActionSheetVC() else { return }
        contentVC.actionSheetType = .account
        contentVC.accountDelegate = self
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.35)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func presentFloatingPanel(with contentVC: UIViewController, layout: FloatingPanelLayout) {
        guard floatingPanel == nil else { return }
        
        let fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        
        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false
        fpc.layout = layout
        fpc.isRemovalInteractionEnabled = true
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
    
        self.floatingPanel = fpc
        self.present(fpc, animated: true)
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

extension ProfileViewController: FloatingPanelControllerDelegate, UITextFieldDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
