//
//  NewPasswordViewController.swift
//  Kitapi
//
//  Created by Suneel on 08/04/26.
// 9-4-26

import UIKit

class NewPasswordViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var newPasswordTextFieldView: CustomTextField!
    @IBOutlet weak var confirmNewPasswordTextFieldView: CustomTextField!
    @IBOutlet weak var otpTextFieldView: CustomTextField!
    
    @IBOutlet weak var resetPasswordButton: UIButton!
    
    var emailToSetNewPassword: String = ""
    
    private let newPasswordViewModel = NewPasswordViewModel()
    
    static var sbIdentifier: String {
        return String(describing: NewPasswordViewController.self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNewPasswordScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func resetPasswordAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.newPasswordViewModel.otpToSetNewPassword = self.otpTextFieldView.customTextField.text ?? ""
        self.newPasswordViewModel.newPassword = self.newPasswordTextFieldView.customTextField.text ?? ""
        self.newPasswordViewModel.emailToSetNewPassword = self.emailToSetNewPassword
        self.newPasswordViewModel.confirmNewPassword = self.confirmNewPasswordTextFieldView.customTextField.text ?? ""
        
        Task {
            await self.newPasswordViewModel.setNewPassword()
        }
    }
    private func bindViewModel() {
        // Bind validation error with field-specific handling
        
        self.newPasswordViewModel.onResetNewPasswordValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
            case .otpField:
                self.otpTextFieldView.showError(message: error.message)
            case .passwordField:
                self.newPasswordTextFieldView.showError(message: error.message)
            case .confirmPasswordField:
                self.confirmNewPasswordTextFieldView.showError(message: error.message)
            default:
                break
            }
        }
        
        // Bind loading state
        self.newPasswordViewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
        }
        
        // Bind API error
        self.newPasswordViewModel.onResetNewPasswordError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        // Bind success
        self.newPasswordViewModel.onResetNewPasswordSuccess = { [weak self] user in
            guard let self = self else { return }
            MessageManager.shared.show(message: user.message, type: .success)
            self.navigateToLogin()
        }
    }
    
    private func clearAllErrors() {
        self.otpTextFieldView.hideErrorMessage()
        self.newPasswordTextFieldView.hideErrorMessage()
        self.confirmNewPasswordTextFieldView.hideErrorMessage()
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

//9-4-26

extension NewPasswordViewController {
    
    private func setNewPasswordScreenUI() {
        
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.newPasswordHeaderTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.subtitleLabel.text = APPConstants.createNewPasswordTitle
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 16)
        self.subtitleLabel.textColor = .labelPlaceholderColor
        self.subtitleLabel.numberOfLines = 2
        
        self.backButton.setTitleColor(.headerLabekColor, for: .normal)
        
        self.otpTextFieldView.customTextField.delegate = self
        self.otpTextFieldView.customTextField.setPlaceholder(text: APPConstants.enterOTPTitle)
        self.otpTextFieldView.placeHolderLabel.text = APPConstants.verifyOTPTitle
        self.otpTextFieldView.customTextField.tag = 0
        
        self.newPasswordTextFieldView.customTextField.delegate = self
        self.newPasswordTextFieldView.customTextField.setPlaceholder(text: APPConstants.newPasswordPlaceholder)
        self.newPasswordTextFieldView.customTextField.isSecureTextEntry = true
        self.newPasswordTextFieldView.showRightEyeView()
        self.newPasswordTextFieldView.dropDownBtn.addTarget(self, action: #selector(self.passwordEyeBtnAction(sender:)), for: .touchUpInside)
        self.newPasswordTextFieldView.placeHolderLabel.text = APPConstants.newPasswordTitle
        self.newPasswordTextFieldView.customTextField.tag = 1
        
        self.confirmNewPasswordTextFieldView.customTextField.delegate = self
        self.confirmNewPasswordTextFieldView.customTextField.setPlaceholder(text: APPConstants.confirmNewPasswordPlaceholder)
        self.confirmNewPasswordTextFieldView.customTextField.isSecureTextEntry = true
        self.confirmNewPasswordTextFieldView.showRightEyeView()
        self.confirmNewPasswordTextFieldView.dropDownBtn.addTarget(self, action: #selector(self.confirmPasswordEyeBtnAction(sender:)), for: .touchUpInside)
        self.confirmNewPasswordTextFieldView.placeHolderLabel.text = APPConstants.confirmNewPasswordTitle
        self.confirmNewPasswordTextFieldView.customTextField.tag = 2
        
        self.resetPasswordButton.setTitle(APPConstants.resetPasswordTitle, for: .normal)
        self.resetPasswordButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.resetPasswordButton.setTitleColor(.white, for: .normal)
        self.resetPasswordButton.backgroundColor = .pinkPrimaryColor
        self.resetPasswordButton.layer.cornerRadius = 25
        
        [self.otpTextFieldView.customTextField, self.newPasswordTextFieldView.customTextField, self.confirmNewPasswordTextFieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
          case 0:
            self.otpTextFieldView.hideError()
        
          case 1:
            self.newPasswordTextFieldView.hideError()
            
        case 2:
            self.confirmNewPasswordTextFieldView.hideError()
              
          default:
              break
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
    
    @objc func passwordEyeBtnAction(sender: UIButton) {
        self.newPasswordTextFieldView.customTextField.isSecureTextEntry = sender.isSelected
        sender.isSelected = !sender.isSelected
    }
    
    @objc func confirmPasswordEyeBtnAction(sender: UIButton) {
        self.confirmNewPasswordTextFieldView.customTextField.isSecureTextEntry = sender.isSelected
        sender.isSelected = !sender.isSelected
    }
}

extension NewPasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        if textField == self.otpTextFieldView.customTextField {
            return string.checkForNumberCount(charsLimit: 6, textField: textField, range: range)
        } else {
            if string.rangeOfCharacter(from: .whitespacesAndNewlines .union(.symbols)) != nil {
                return false
            }
        }
        return true
    }
}
