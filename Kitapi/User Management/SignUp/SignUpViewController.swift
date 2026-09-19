//
//  SignUpViewController.swift
//  Kitapi
//
//  Created by Suneel on 02/04/26.
//

import UIKit
import DropDown

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var createParentAccLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var addProfilePhotoView: UIView!
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var editProfilePhotoBtn: UIButton!
    
    @IBOutlet weak var nameTextFieldView: CustomTextField!
    @IBOutlet weak var emailTextFieldView: CustomTextField!
    @IBOutlet weak var genderTextFieldView: CustomTextField!
    @IBOutlet weak var passwordTextFieldView: CustomTextField!
    @IBOutlet weak var confirmPasswordTextFieldView: CustomTextField!
    
    @IBOutlet weak var phoneNumberPlaceholder: UILabel!
    @IBOutlet weak var phoneNumberTextFieldView: CustomTextField!
    
    @IBOutlet weak var countryCodeButton: UIButton!
    @IBOutlet weak var countryCodeLabel: UILabel!
    @IBOutlet weak var TandCButton: UIButton!
    @IBOutlet weak var termsConditionsLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var signUpBtn: UIButton!
    fileprivate let genderDropDown = DropDown()
    
    private let viewModel = RegisterViewModel()
    
    static var sbIdentifier: String {
        return String(describing: SignUpViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setSignUpScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func selectCountryCodeAction(_ sender: UIButton) {
    }
    @IBAction func editProfilePhotoAction(_ sender: UIButton) {
    }
    
    @IBAction func TandCBtnAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    //16-04
    
    @IBAction func signUpAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        // Update view model with text field values
        self.viewModel.name = self.nameTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.email = self.emailTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.password = self.passwordTextFieldView.customTextField.text ?? ""
        self.viewModel.phone = self.phoneNumberTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.gender = self.genderTextFieldView.customTextField.text ?? ""
        self.viewModel.confirmPassword = self.confirmPasswordTextFieldView.customTextField.text ?? ""
        Task {
            await self.viewModel.register()
        }
    }
    
    private func bindViewModel() {
        // Bind validation error with field-specific handling
        
        self.viewModel.onValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
            case .nameField:
                self.nameTextFieldView.showError(message: error.message)
            case .emailField:
                self.emailTextFieldView.showError(message: error.message)
            case .genderField:
                self.genderTextFieldView.showError(message: error.message)
            case .passwordField:
                self.passwordTextFieldView.showError(message: error.message)
            case .confirmPasswordField:
                self.confirmPasswordTextFieldView.showError(message: error.message)
            default:
                break
            }
        }
        
        // Bind loading state
        self.viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
        
            self.signUpBtn.isEnabled = !isLoading
            self.signUpBtn.alpha = isLoading ? 0.6 : 1.0
        }
        
        // Bind API error
        self.viewModel.onError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        // Bind success
        self.viewModel.onSuccess = { [weak self] user in
            guard let self = self else { return }
            self.handleRegistrationSuccess(user: user)
        }
    }
  
    private func clearAllErrors() {
        self.nameTextFieldView.hideErrorMessage()
        self.emailTextFieldView.hideErrorMessage()
        self.phoneNumberTextFieldView.hideErrorMessage()
        self.genderTextFieldView.hideErrorMessage()
        self.passwordTextFieldView.hideErrorMessage()
        self.confirmPasswordTextFieldView.hideErrorMessage()
       }
    
     private func handleRegistrationSuccess(user: User) {
         self.openVerifyOTPVC(user: user)
     }
}



//MARK: ------------ UI-------------

extension SignUpViewController {
    
    private func setSignUpScreenUI() {
        
        self.appBGView.setGradientBackground()
        
        //03-04
        
        self.createParentAccLabel.text = APPConstants.createParentAcc
        self.createParentAccLabel.textAlignment = .center
        self.createParentAccLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.createParentAccLabel.textColor = .headerLabekColor
        self.createParentAccLabel.numberOfLines = 1
        
        self.addProfilePhotoView.layer.cornerRadius = 45
        self.addProfilePhotoView.layer.borderWidth = 1
        self.addProfilePhotoView.layer.borderColor = UIColor.borderColor.cgColor
        
        self.profilePhotoImageView.layer.cornerRadius = 45
        
        self.signUpBtn.setTitle(APPConstants.createParentAcc, for: .normal)
        self.signUpBtn.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.signUpBtn.setTitleColor(.white, for: .normal)
        self.signUpBtn.backgroundColor = .pinkPrimaryColor
        self.signUpBtn.layer.cornerRadius = 25
        
        self.addTapGestureForTerms()
        self.addTapGestureToLogin()
        self.setupGenderDropdown()
        
        self.nameTextFieldView.customTextField.delegate = self
        self.nameTextFieldView.customTextField.setPlaceholder(text: APPConstants.fullNamePlaceholder)
        self.nameTextFieldView.placeHolderLabel.text = APPConstants.fullNameTitle
        self.nameTextFieldView.customTextField.tag = 0
        
        self.genderTextFieldView.customTextField.delegate = self
        self.genderTextFieldView.customTextField.setPlaceholder(text: APPConstants.genderPlaceholder)
        self.genderTextFieldView.placeHolderLabel.text = APPConstants.genderTitle
        self.genderTextFieldView.customTextField.tag = 2
        self.genderTextFieldView.showRightView()
        
        self.emailTextFieldView.customTextField.delegate = self
        self.emailTextFieldView.customTextField.setPlaceholder(text: APPConstants.emailPlaceHolder)
        self.emailTextFieldView.placeHolderLabel.text = APPConstants.emailTitle
        self.emailTextFieldView.customTextField.tag = 1
        
        self.passwordTextFieldView.customTextField.delegate = self
        self.passwordTextFieldView.customTextField.setPlaceholder(text: APPConstants.passwordPlaceholder)
        self.passwordTextFieldView.customTextField.isSecureTextEntry = true
        self.passwordTextFieldView.showRightEyeView()
        self.passwordTextFieldView.dropDownBtn.addTarget(self, action: #selector(self.passwordEyeBtnAction(sender:)), for: .touchUpInside)
        self.passwordTextFieldView.placeHolderLabel.text = APPConstants.passwordTitle
        self.passwordTextFieldView.customTextField.tag = 4
        
        self.confirmPasswordTextFieldView.customTextField.delegate = self
        self.confirmPasswordTextFieldView.customTextField.setPlaceholder(text: APPConstants.confirmPasswordPlaceholder)
        self.confirmPasswordTextFieldView.customTextField.isSecureTextEntry = true
        self.confirmPasswordTextFieldView.showRightEyeView()
        self.confirmPasswordTextFieldView.dropDownBtn.addTarget(self, action: #selector(self.confirmPasswordEyeBtnAction(sender:)), for: .touchUpInside)
        self.confirmPasswordTextFieldView.placeHolderLabel.text = APPConstants.confirmPasswordTitle
        self.confirmPasswordTextFieldView.customTextField.tag = 5
        
        self.termsConditionsLabel.numberOfLines = 1
        self.termsConditionsLabel.textAlignment = .left
        
        self.loginLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.loginLabel.numberOfLines = 1
        self.loginLabel.isUserInteractionEnabled = true
        
        self.TandCButton.setImage(AppImages.checkmark_unselected, for: .normal)
        self.TandCButton.setImage(AppImages.checkmark_selected, for: .selected)
        
        //9-4
        
        self.phoneNumberTextFieldView.customTextField.delegate = self
        self.phoneNumberTextFieldView.customTextField.setPlaceholder(text: APPConstants.phoneNumberPlaceholder)
        self.phoneNumberTextFieldView.errorLabel.textAlignment = .right
        self.phoneNumberTextFieldView.customTextField.tag = 3
        
        self.phoneNumberPlaceholder.text = APPConstants.phoneNumberTitle
        self.phoneNumberPlaceholder.textAlignment = .left
        self.phoneNumberPlaceholder.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        self.phoneNumberPlaceholder.textColor = .labelPlaceholderColor
        self.phoneNumberPlaceholder.numberOfLines = 1
        
        self.countryCodeButton.layer.cornerRadius = 15
        self.countryCodeButton.layer.borderWidth = 0.5
        self.countryCodeButton.layer.borderColor = UIColor.borderColor.cgColor
        
        self.countryCodeLabel.text = "+91"
        self.countryCodeLabel.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.countryCodeLabel.textColor = .textColor
        self.countryCodeLabel.textAlignment = .left
        self.countryCodeLabel.numberOfLines = 1
        
        //16-04
        
        // Add text change listeners to hide errors on typing
        [self.nameTextFieldView.customTextField, self.emailTextFieldView.customTextField, self.phoneNumberTextFieldView.customTextField, self.genderTextFieldView.customTextField, self.passwordTextFieldView.customTextField, self.confirmPasswordTextFieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(genderFieldTapped))
        self.genderTextFieldView.customTextField.addGestureRecognizer(tap)
        self.genderTextFieldView.customTextField.isUserInteractionEnabled = true
        
    }
      @objc private func textFieldDidChange(_ textField: UITextField) {
          
          switch textField.tag {
            case 0:
              self.nameTextFieldView.hideError()
                
            case 1:
              self.emailTextFieldView.hideError()
                
            case 2:
              self.genderTextFieldView.hideError()
                
            case 3:
              self.phoneNumberTextFieldView.hideError()
                
            case 4:
              self.passwordTextFieldView.hideError()
              
          case 5:
              self.confirmPasswordTextFieldView.hideError()
                
            default:
                break
            }
      }
    
    private func setupGenderDropdown() {
        
        self.genderDropDown.anchorView = genderTextFieldView.customTextField
        self.genderDropDown.dataSource = ["Male", "Female"]
        self.genderDropDown.bottomOffset = CGPoint(
            x: 0,
            y: genderTextFieldView.customTextField.bounds.height
        )
        
        self.genderDropDown.selectionAction = { [weak self] index, item in
            self?.genderTextFieldView.customTextField.text = item
            self?.viewModel.gender = item.lowercased()
            
            // Hide error if any
            self?.genderTextFieldView.hideError()
        }
    }
    
    @objc func genderFieldTapped() {
        self.view.endEditing(true)
        self.genderDropDown.show()
    }
    
    @objc func passwordEyeBtnAction(sender: UIButton) {
        self.passwordTextFieldView.customTextField.isSecureTextEntry = sender.isSelected
        sender.isSelected = !sender.isSelected
    }

    @objc func confirmPasswordEyeBtnAction(sender: UIButton) {
        self.confirmPasswordTextFieldView.customTextField.isSecureTextEntry = sender.isSelected
        sender.isSelected = !sender.isSelected
    }
    
    //15-04
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

    private func addTapGestureForTerms() {
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textPlaceholderColor,
            .font: UIFont(name: Fonts.urbanistRegular, size: 14)!
        ]
        let viewMoreAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.pinkPrimaryColor,
            .font: UIFont(name: Fonts.urbanistSemiBold, size: 14)!
        ]
        
        let fullString = NSMutableAttributedString(string: APPConstants.acceptTandC, attributes: baseAttributes)
        let viewMore = NSAttributedString(string: APPConstants.TandCTitle, attributes: viewMoreAttributes)
        fullString.append(viewMore)
     
        self.termsConditionsLabel.attributedText = fullString
    }


    private func addTapGestureToLogin() {

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textPlaceholderColor
        ]
        let viewMoreAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.pinkPrimaryColor
        ]
        
        let fullString = NSMutableAttributedString(string: APPConstants.oldUserTitle, attributes: baseAttributes)
        let viewMore = NSAttributedString(string: APPConstants.loginTitle, attributes: viewMoreAttributes)
        fullString.append(viewMore)
        
        self.loginLabel.attributedText = fullString
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnLabel(_ :)))
        tapgesture.numberOfTapsRequired = 1
        tapgesture.numberOfTouchesRequired = 1
        self.loginLabel.addGestureRecognizer(tapgesture)
    }

    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {

        let signUpTitleRange =  NSRange(location: 28, length: APPConstants.loginTitle.count)
        if gesture.didTapAttributedTextInLabel(label: self.loginLabel, inRange: signUpTitleRange) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func openVerifyOTPVC(user: User) {
        guard let vc = VCManager.openVerifyOTPVC() else { return }
        vc.emailOfTheUser = user.email
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField == self.nameTextFieldView.customTextField)  {
          return string.allowOnlyCharcters()
        }
        else if (textField == self.passwordTextFieldView.customTextField) || (textField == self.confirmPasswordTextFieldView.customTextField) {
            if string.rangeOfCharacter(from: .whitespaces) != nil {
                return false
            }
        }
        else if textField == self.phoneNumberTextFieldView.customTextField {
            return string.checkForNumberCount(charsLimit: 10, textField: textField, range: range)
        }
        return true
    }
}
