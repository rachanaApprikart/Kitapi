//
//  MPINViewController.swift
//  Kitapi
//
//  Created by Suneel on 03/08/26.
//

import UIKit
import FloatingPanel

class MPINViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var mpinView: MPINView!
    
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var createBiometricButton: UIButton!
    @IBOutlet weak var createMPINButton: UIButton!
    
    @IBOutlet weak var forgotMPINButton: UIButton!
    
    private var floatingPanel: FloatingPanelController?
    private let viewModel = MPINViewModel()
    var selectedMinute: String?
    
    weak var delegate: CreateMPINDelegate?
    weak var disableDelegate: DisableChildModeDelegate?

    var mode: MPINMode = .enable
    
    static var sbIdentifier: String {
        return String(describing: MPINViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setMPINUI()
        self.configureUI(for: mode)
        self.bindViewModel()
    }
    
    @IBAction func createMPINAction(_ sender: UIButton) {
        let pin = self.mpinView.getMPIN()
        
        switch mode {
        case .create:
            self.createMPIN(pin: pin)
            
        case .enable:
            self.enableChildMode(pin: pin)
            
        case .disable:
            self.disableChildMode(pin: pin)
        }
    }
    
    
    @IBAction func forgotMPINAction(_ sender: UIButton) {
        self.showResetMPINVC()
    }
    
    @IBAction func createBiometricAction(_ sender: UIButton) {
    }
    
    private func createMPIN(pin: String) {
        Task {
            await self.viewModel.createMPIN(mpin: pin)
        }
    }
    
    private func enableChildMode(pin: String) {
        guard let id = ChildManager.shared.selectedChild?.id else { return }
        guard let duration = self.selectedMinute else { return }

        self.viewModel.childID = id
        self.viewModel.duration = duration
        
        Task {
            await self.viewModel.enableChildMode(mpin: pin)
        }
    }
    
    private func disableChildMode(pin: String) {
        Task {
            await self.viewModel.disableChildModeWithMPIN(mpin: pin)
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.onLoadingChanged = { [weak self] isApiLoading in
            guard let self = self else { return }
            isApiLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.createMPINButton.isEnabled = !isApiLoading
            self.createMPINButton.alpha = isApiLoading ? 0.6 : 1.0
        }
        
        self.viewModel.onCreateMPINError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewModel.onCreateMPINSuccess = { [weak self] mpinResponse in
            MessageManager.shared.show(message: mpinResponse.message, type: .success)
            // First-time MPIN creation only. Stay in Parent Mode.
            self?.delegate?.mpinCreatedSuccessfully()
        }
        
        self.viewModel.onEnableChildModeError = { [weak self] errorMsg in
            MessageManager.shared.show(message: errorMsg)
        }
        
        self.viewModel.onEnableChildModeSuccess = { [weak self] resp in
            MessageManager.shared.show(message: resp.message, type: .success)
            let data = resp.data
            
            if let child = ChildManager.shared.selectedChild {
                ChildSessionManager.shared.updateSelectedChild(child)
            }
            
            ChildSessionManager.shared.startChildModeSession(
                token: data.token,
                startTime: data.startTime,
                expiresAt: data.expiresAt,
                sessionDuration: data.sessionDuration
            )
            ChildManager.shared.isChildMode = true
            self?.navigateToChildTabBar()
        }
        
        self.viewModel.onDisableChildModeError = { [weak self] errorMsg in
            MessageManager.shared.show(message: errorMsg)
        }
        
        self.viewModel.onDisableChildModeSuccess = { [weak self] resp in
            MessageManager.shared.show(message: resp.message, type: .success)
            self?.disableDelegate?.didDisableChildModeSuccessfully()
        }
    }
    
    fileprivate func navigateToChildTabBar() {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
              let vc = VCManager.openChildTabBarVC() else {
            return
        }
        sceneDelegate.window?.rootViewController = vc
    }
    
    fileprivate func returnToLoginAfterMPINReset() {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
              let vc = VCManager.openLoginVC() else {
            return
        }
        sceneDelegate.window?.rootViewController = vc
    }
}
//4-8

extension MPINViewController {
    
    private func configureUI(for mode: MPINMode) {
        self.headerLabel.text = mode.title
        self.subtitleLabel.text = mode.subtitle
        self.createMPINButton.setTitle(mode.buttonTitle, for: .normal)
        
        switch mode {
            
        case .create:
            self.forgotMPINButton.isHidden = true
            
        default:
            self.forgotMPINButton.isHidden = false
        }
    }
    
    private func setMPINUI() {
        
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.subtitleLabel.textColor = .labelPlaceholderColor
        self.subtitleLabel.numberOfLines = 2
        
        self.orLabel.textAlignment = .center
        self.orLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 14)
        self.orLabel.textColor = .buttonTitleColor
        self.orLabel.numberOfLines = 1
        
        self.createMPINButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.createMPINButton.setTitleColor(.white, for: .normal)
        self.createMPINButton.backgroundColor = .pinkPrimaryColor
        self.createMPINButton.layer.cornerRadius = 25
        
        self.createBiometricButton.setTitle("Use Biometric", for: .normal)
        self.createBiometricButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.createBiometricButton.setTitleColor(UIColor.buttonTitleColor, for: .normal)
        self.createBiometricButton.backgroundColor = .white
        self.createBiometricButton.layer.cornerRadius = 25
        self.createBiometricButton.layer.borderWidth = 1
        self.createBiometricButton.layer.borderColor = UIColor.buttonBorderColor.cgColor
        
        self.forgotMPINButton.setTitle("Forgot MPIN?", for: .normal)
        self.forgotMPINButton.contentVerticalAlignment = .top
        self.forgotMPINButton.contentHorizontalAlignment = .right
        self.forgotMPINButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.forgotMPINButton.setTitleColor(.textPlaceholderColor, for: .normal)
        
        
        //Keeps button blurred initially
        self.updateMPINButtonState()
        
        //Keeps button blurred while editing
        self.mpinView.onMPINChanged = { [weak self] mpin in
            self?.updateMPINButtonState()
        }
        
        //Button loks clear on completing
        self.mpinView.onMPINComplete = { [weak self] mpin in
            self?.updateMPINButtonState()
        }
    }
    
    private func updateMPINButtonState() {
        let otp = self.mpinView.getMPIN()
        let isComplete = otp.count == 4
        
        UIView.animate(withDuration: 0.3) {
            self.createMPINButton.isEnabled = isComplete
            self.createMPINButton.alpha = isComplete ? 1.0 : 0.6
        }
    }
    
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicator.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.view.sendSubviewToBack(self.activityView)
        self.activityIndicator.stopAnimating()
    }
    
    private func showResetMPINVC() {
        guard let contentVC = VCManager.openResetMPINVC() else { return }
        
        contentVC.onResetSuccess = { [weak self] in
            
            AppUserDefaults.authorizationToken = nil
            AppUserDefaults.customerDetails = nil
            ChildManager.shared.clearChildMode()
            
            self?.floatingPanel?.dismiss(animated: true)
            self?.floatingPanel = nil
            self?.returnToLoginAfterMPINReset()
        }
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.4)
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
    
}

protocol CreateMPINDelegate: AnyObject {
    func mpinCreatedSuccessfully()
}

protocol DisableChildModeDelegate: AnyObject {
    func didDisableChildModeSuccessfully()
}


extension MPINViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
//The expected behavior is:
//- .create: Forgot MPIN remains hidden.
//- .enable and .disable: Forgot MPIN remains visible.
//- Reset succeeds: return to the Login screen, not the parent or child tab bar.
//- Reset fails: keep the reset panel open and display the error.
