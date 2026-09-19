//
//  LoginViewController.swift
//  Kitapi
//
//  Created by Suneel on 31/03/26.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet var appBGView: UIView!
    @IBOutlet weak var signInHeaderLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var passwordTextFieldView: CustomTextField!
    @IBOutlet weak var emailTextFieldView: CustomTextField!
    
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var newUserLabel: UILabel!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var alternateLoginLabel: UILabel!
    @IBOutlet weak var whatsappLoginButton: UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!
    
    private let loginViewModel = LoginViewModel()
    
    static var sbIdentifier: String {
        return String(describing: LoginViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLoginScreenUI()
        self.bindViewModel()
    }
    @IBAction func loginButtonAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.loginViewModel.loginEmail = emailTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.loginViewModel.loginPassword = self.passwordTextFieldView.customTextField.text ?? ""
        self.loginViewModel.deviceVersion = UIDevice.current.systemVersion
        
        Task {
            await self.loginViewModel.register()
        }
    }
    
    @IBAction func googlrLoginAction(_ sender: UIButton) {
    }
    
    @IBAction func resetPasswordAction(_ sender: UIButton) {
        self.openResetPasswordVC()
    }
    
    @IBAction func whatsappLoginAction(_ sender: UIButton) {
    }
    
    private func bindViewModel() {
        // Bind validation error with field-specific handling
        
        self.loginViewModel.onLoginValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
            case .emailField:
                self.emailTextFieldView.showError(message: error.message)
            case .passwordField:
                self.passwordTextFieldView.showError(message: error.message)
            default:
                break
            }
        }
        self.loginViewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.loginButton.isEnabled = !isLoading
            self.loginButton.alpha = isLoading ? 0.6 : 1.0
        }
        self.loginViewModel.onLoginError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.loginViewModel.onLoginSuccess = { [weak self] verifiedParent in
            guard let self = self else { return }
            AppUserDefaults.authorizationToken = verifiedParent.token
            self.retrieveParentDetails()
        }
        
        self.loginViewModel.onGetParentDetailsSuccess = { [weak self] verifiedParent in
            guard let self = self else { return }
            AppUserDefaults.customerDetails = verifiedParent.user
            MessageManager.shared.show(message: verifiedParent.message, type: .success)
            self.navigateToTabBar()
        }
    }
    
    private func retrieveParentDetails() {
        Task {
            await self.loginViewModel.getParentDetails()
        }
    }
    
    private func clearAllErrors() {
        self.emailTextFieldView.hideErrorMessage()
        self.passwordTextFieldView.hideErrorMessage()
    }

    
    fileprivate func navigateToTabBar() {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
                let vc = VCManager.openTabBarVC() else {
                    return
                }
       
        sceneDelegate.window?.rootViewController = vc
    }
}


//MARK: - -----------UI---------------
extension LoginViewController {
    
    private func setLoginScreenUI() {
        //01-04
        self.appBGView.setGradientBackground()
        
        self.signInHeaderLabel.text = APPConstants.loginTitle
        self.signInHeaderLabel.textAlignment = .center
        self.signInHeaderLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.signInHeaderLabel.textColor = .headerLabekColor
        self.signInHeaderLabel.numberOfLines = 1
        
        self.forgetPasswordButton.setTitle(APPConstants.forgotPasswordTitle, for: .normal)
        self.forgetPasswordButton.contentVerticalAlignment = .top
        self.forgetPasswordButton.contentHorizontalAlignment = .right
        self.forgetPasswordButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.forgetPasswordButton.setTitleColor(.textPlaceholderColor, for: .normal)
        
        self.loginButton.setTitle(APPConstants.loginTitle, for: .normal)
        self.loginButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.loginButton.setTitleColor(.white, for: .normal)
        self.loginButton.backgroundColor = .pinkPrimaryColor
        self.loginButton.layer.cornerRadius = 25
        
        self.emailTextFieldView.customTextField.delegate = self
        self.emailTextFieldView.customTextField.setPlaceholder(text: APPConstants.emailPlaceHolder)
        self.emailTextFieldView.placeHolderLabel.text = APPConstants.emailTitle
        self.emailTextFieldView.customTextField.tag = 0
        
        self.passwordTextFieldView.customTextField.delegate = self
        self.passwordTextFieldView.customTextField.setPlaceholder(text: APPConstants.passwordPlaceholder)
        self.passwordTextFieldView.placeHolderLabel.text = APPConstants.passwordTitle
        self.passwordTextFieldView.customTextField.tag = 1
        
        self.passwordTextFieldView.showRightEyeView()
        self.passwordTextFieldView.dropDownBtn.addTarget(self, action: #selector(self.passwordEyeBtnAction(sender:)), for: .touchUpInside)
        self.passwordTextFieldView.customTextField.isSecureTextEntry = true
        
        self.newUserLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.newUserLabel.numberOfLines = 1
        self.newUserLabel.isUserInteractionEnabled = true
        
        //02-04
        
        self.googleLoginButton.setTitle(APPConstants.googleTitle, for: .normal)
        self.googleLoginButton.titleLabel?.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        self.googleLoginButton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.googleLoginButton.layer.cornerRadius = 25
        self.googleLoginButton.layer.borderColor = UIColor.borderColor.cgColor
        self.googleLoginButton.layer.borderWidth = 1

        self.whatsappLoginButton.setTitle(APPConstants.whatsappTitle, for: .normal)
        self.whatsappLoginButton.titleLabel?.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        self.whatsappLoginButton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.whatsappLoginButton.layer.cornerRadius = 25
        self.whatsappLoginButton.layer.borderColor = UIColor.borderColor.cgColor
        self.whatsappLoginButton.layer.borderWidth = 1
        
        self.alternateLoginLabel.text = APPConstants.alternateLoginTitle
        self.alternateLoginLabel.textAlignment = .center
        self.alternateLoginLabel.font = UIFont(name: Fonts.urbanistBold, size: 16)
        self.alternateLoginLabel.textColor = .textPlaceholderColor
        self.alternateLoginLabel.numberOfLines = 1
        
        self.addTapGestureForSignUp()
        
        [self.emailTextFieldView.customTextField, self.passwordTextFieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
          case 0:
            self.emailTextFieldView.hideError()
              
          case 1:
            self.passwordTextFieldView.hideError()
              
          default:
              break
          }
    }
  
    @objc func passwordEyeBtnAction(sender: UIButton) {
        self.passwordTextFieldView.customTextField.isSecureTextEntry = sender.isSelected
        sender.isSelected = !sender.isSelected
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
    
    private func addTapGestureForSignUp() {
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textPlaceholderColor
        ]
        let viewMoreAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.pinkPrimaryColor
        ]
        
        let fullString = NSMutableAttributedString(string: APPConstants.newUserTitle, attributes: baseAttributes)
        let viewMore = NSAttributedString(string: APPConstants.signUpTitle, attributes: viewMoreAttributes)
        fullString.append(viewMore)
        
        self.newUserLabel.attributedText = fullString
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnLabel(_ :)))
        tapgesture.numberOfTapsRequired = 1
        tapgesture.numberOfTouchesRequired = 1
        self.newUserLabel.addGestureRecognizer(tapgesture)
    }
    
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        
        let signUpTitleRange =  NSRange(location: 27, length: APPConstants.signUpTitle.count)
        if gesture.didTapAttributedTextInLabel(label: self.newUserLabel, inRange: signUpTitleRange) {
            self.openSignUpVC()
        }
    }
    
    private func openSignUpVC() {
        guard let vc = VCManager.openSignUpVC() else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openResetPasswordVC() {
        guard let vc = VCManager.openResetPasswordVC() else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
