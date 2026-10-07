//
//  UpdateMPINViewController.swift
//  Kitapi
//
//  Created by Suneel on 01/10/26.
//

import UIKit

class UpdateMPINViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var currentMPINTextFieldView: CustomTextField!
    @IBOutlet weak var newMPINTextFieldView: CustomTextField!
    
    @IBOutlet weak var updateMPINButton: UIButton!
    
    private let updateMPINViewModel = UpdateMPINViewModel()
    weak var delegate: UpdateMPINDelegate?

    static var sbIdentifier: String {
        return String(describing: UpdateMPINViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpdateMPINScreenUI()
        self.bindViewModel()
    }

    @IBAction func updateMPINAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.updateMPINViewModel.currentMPIN = self.currentMPINTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.updateMPINViewModel.newMPIN = self.newMPINTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        Task {
            await self.updateMPINViewModel.registerChangeMPIN()
        }
    }
    
    private func bindViewModel() {
        // Bind validation error with field-specific handling
        
        self.updateMPINViewModel.onChangeMPINValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
                
            case .currentMPIN:
                self.currentMPINTextFieldView.showError(message: error.message)
            case .newMPIN:
                self.newMPINTextFieldView.showError(message: error.message)
            default:
                break
            }
        }
        self.updateMPINViewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.updateMPINButton.isEnabled = !isLoading
            self.updateMPINButton.alpha = isLoading ? 0.6 : 1.0
        }
        self.updateMPINViewModel.onChangeMPINError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.updateMPINViewModel.onChangeMPINESuccess = { [weak self] verifiedParent in
            guard let self = self else { return }
            self.delegate?.mpinChangedSuccessfully()
        }
    }
}

//MARK: ------------- UI ------

extension UpdateMPINViewController {
    
    private func setUpdateMPINScreenUI() {
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.changeMPINTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.updateMPINButton.setTitle(APPConstants.updateMPINTitle, for: .normal)
        self.updateMPINButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.updateMPINButton.setTitleColor(.white, for: .normal)
        self.updateMPINButton.backgroundColor = .pinkPrimaryColor
        self.updateMPINButton.layer.cornerRadius = 25
        
        self.currentMPINTextFieldView.customTextField.delegate = self
        self.currentMPINTextFieldView.customTextField.setPlaceholder(text: APPConstants.currentMPINPlaceholder)
        self.currentMPINTextFieldView.placeHolderLabel.text = APPConstants.currentMPINTitle
        self.currentMPINTextFieldView.customTextField.tag = 0
        
        self.newMPINTextFieldView.customTextField.delegate = self
        self.newMPINTextFieldView.customTextField.setPlaceholder(text: APPConstants.newMPINPlaceholder)
        self.newMPINTextFieldView.placeHolderLabel.text = APPConstants.newMPINTitle
        self.newMPINTextFieldView.customTextField.tag = 1
        
        [self.currentMPINTextFieldView.customTextField, self.newMPINTextFieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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

extension UpdateMPINViewController: UITextFieldDelegate {
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
          case 0:
            self.currentMPINTextFieldView.hideError()

          case 1:
            self.newMPINTextFieldView.hideError()

          default:
              break
          }
    }
    
    private func clearAllErrors() {
        self.currentMPINTextFieldView.hideError()
        self.newMPINTextFieldView.hideError()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.currentMPINTextFieldView.customTextField ||
              textField == self.newMPINTextFieldView.customTextField {

               return string.checkForNumberCount(
                   charsLimit: 4,
                   textField: textField,
                   range: range
               )
           }

           return true
    }
}

protocol UpdateMPINDelegate: AnyObject {
    func  mpinChangedSuccessfully()
}
