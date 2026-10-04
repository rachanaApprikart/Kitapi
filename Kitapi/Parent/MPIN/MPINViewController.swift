//
//  MPINViewController.swift
//  Kitapi
//
//  Created by Suneel on 03/08/26.
//

import UIKit

class MPINViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var mpinView: MPINView!
    
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var createBiometricButton: UIButton!
    @IBOutlet weak var createMPINButton: UIButton!
    
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
}
//4-8

extension MPINViewController {
    
    private func configureUI(for mode: MPINMode) {
        self.headerLabel.text = mode.title
        self.subtitleLabel.text = mode.subtitle
        self.createMPINButton.setTitle(mode.buttonTitle, for: .normal)
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
    
}

protocol CreateMPINDelegate: AnyObject {
    func mpinCreatedSuccessfully()
}

protocol DisableChildModeDelegate: AnyObject {
    func didDisableChildModeSuccessfully()
}
