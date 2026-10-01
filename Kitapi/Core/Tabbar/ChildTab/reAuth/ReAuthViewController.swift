//
//  ReAuthViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/09/26.
//

import UIKit

class ReAuthViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var mpinView: MPINView!
    
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var enterBiometricButton: UIButton!
    @IBOutlet weak var enterMPINButton: UIButton!
    
    private let viewModel = ReAuthViewModel()
    weak var delegate: ReAuthDelegate?
    
    static var sbIdentifier: String {
        return String(describing: ReAuthViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setReauthMPINUI()
        self.bindViewModel()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func enterMPINAction(_ sender: UIButton) {
        let pin = self.mpinView.getMPIN()
        
        Task {
            await self.viewModel.reauthenticate(mpin: pin)
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.onLoadingChanged = { [weak self] isApiLoading in
            guard let self = self else { return }
            isApiLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.enterMPINButton.isEnabled = !isApiLoading
            self.enterMPINButton.alpha = isApiLoading ? 0.6 : 1.0
        }
        
        self.viewModel.onReauthError = { [weak self] errorMsg in
               MessageManager.shared.show(message: errorMsg)
               // stays on screen — matches "Failure → Stay MPIN" from the original diagram
           }
           
           self.viewModel.onReauthSuccess = { [weak self] resp in
               MessageManager.shared.show(message: resp.message, type: .success)
               self?.delegate?.didReauthSuccessfully()
        }
    }
}

extension ReAuthViewController {
    
  
    private func setReauthMPINUI() {
        
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        self.headerLabel.text = "Enter MPIN to Re-Auth"
        
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.subtitleLabel.textColor = .labelPlaceholderColor
        self.subtitleLabel.numberOfLines = 2
        self.subtitleLabel.text = "To re-authenticate to parent mode enter your MPIN"

        self.orLabel.textAlignment = .center
        self.orLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 14)
        self.orLabel.textColor = .buttonTitleColor
        self.orLabel.numberOfLines = 1
        
        self.enterMPINButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.enterMPINButton.setTitleColor(.white, for: .normal)
        self.enterMPINButton.backgroundColor = .pinkPrimaryColor
        self.enterMPINButton.layer.cornerRadius = 25
        self.enterMPINButton.setTitle("Enter", for: .normal)

        self.enterBiometricButton.setTitle("Use Biometric", for: .normal)
        self.enterBiometricButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.enterBiometricButton.setTitleColor(UIColor.buttonTitleColor, for: .normal)
        self.enterBiometricButton.backgroundColor = .white
        self.enterBiometricButton.layer.cornerRadius = 25
        self.enterBiometricButton.layer.borderWidth = 1
        self.enterBiometricButton.layer.borderColor = UIColor.buttonBorderColor.cgColor
        
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
            self.enterMPINButton.isEnabled = isComplete
            self.enterMPINButton.alpha = isComplete ? 1.0 : 0.6
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

