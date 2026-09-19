//
//  ResetPasswordViewController.swift
//  Kitapi
//
//  Created by Suneel on 08/04/26.
//

import UIKit

class ResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var emailTextField: CustomTextField!
    
    @IBOutlet weak var verifyEmailButton: UIButton!
    @IBOutlet weak var backToLoginButton: UIButton!
    
    private let resetPasswordViewModel = ResetPasswordViewModel()
    
    static var sbIdentifier: String {
        return String(describing: ResetPasswordViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setResetPasswordScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func verifyEmailAction(_ sender: UIButton) {
        self.emailTextField.hideErrorMessage()
        self.view.endEditing(true)

        self.resetPasswordViewModel.emailToResetPassword = emailTextField.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        Task {
            await self.resetPasswordViewModel.sendOTP()
        }
       
    }
    
    @IBAction func backToLoginAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func bindViewModel() {
        
        self.resetPasswordViewModel.onValidationErrorInEmailField = { [weak self] error in
            guard let self = self else { return }
            
            self.emailTextField.hideErrorMessage()
            
            switch error.field {
                
            case .emailField:
                self.emailTextField.showError(message: error.message)
                
            default:
                break
            }
        }
        
        // Bind loading state
        self.resetPasswordViewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        // Bind API error
        self.resetPasswordViewModel.onErrorToResetPassword = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        // Bind success
        self.resetPasswordViewModel.onSuccessToResetPassword = { [weak self] forgotPassResponse in
            guard let self = self else { return }
            MessageManager.shared.show(message: forgotPassResponse.message, type: .success)
            self.openNewPasswordVC()
        }
    }
    
    private func openNewPasswordVC() {
        guard let vc = VCManager.openNewPasswordVC() else { return }
        vc.emailToSetNewPassword = self.resetPasswordViewModel.emailToResetPassword
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ResetPasswordViewController {
    
    private func setResetPasswordScreenUI() {
        
        self.appBGView.setGradientBackground()
        
        //8-4-26
        
        self.headerLabel.text = APPConstants.resetPasswordTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.subtitleLabel.text = APPConstants.resetPasswordSubTitle
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 16)
        self.subtitleLabel.textColor = .labelPlaceholderColor
        self.subtitleLabel.numberOfLines = 2
        
        self.emailTextField.customTextField.delegate = self
        self.emailTextField.customTextField.setPlaceholder(text: APPConstants.emailPlaceHolder)
        self.emailTextField.placeHolderLabel.text = APPConstants.emailTitle
        self.emailTextField.customTextField.tag = 0
        self.emailTextField.customTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.backButton.setTitleColor(.headerLabekColor, for: .normal)
        
        self.verifyEmailButton.setTitle(APPConstants.resetPasswordBtnTitle, for: .normal)
        self.verifyEmailButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.verifyEmailButton.setTitleColor(.white, for: .normal)
        self.verifyEmailButton.backgroundColor = .pinkPrimaryColor
        self.verifyEmailButton.layer.cornerRadius = 25
        
        self.backToLoginButton.setTitle(APPConstants.backToLoginBtnTitle, for: .normal)
        self.backToLoginButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.backToLoginButton.setTitleColor(.pinkPrimaryColor, for: .normal)
        self.backToLoginButton.backgroundColor = .white
        self.backToLoginButton.layer.cornerRadius = 25
        self.backToLoginButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.backToLoginButton.layer.borderWidth = 1
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


extension ResetPasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        self.emailTextField.hideError()
    }
}
