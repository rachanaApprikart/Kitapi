//
//  ResetMPINViewController.swift
//  Kitapi
//
//  Created by Suneel on 15/10/26.
//

import UIKit

class ResetMPINViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var newMPINTextFieldView: CustomTextField!
    
    @IBOutlet weak var resetMPINButton: UIButton!
    
    private let resetMPINViewModel = ResetMPINViewModel()
    var onResetSuccess: (() -> Void)?
    
    static var sbIdentifier: String {
        return String(describing: ResetMPINViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetMPINScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func resetMPINAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.resetMPINViewModel.newMPIN = self.newMPINTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        Task {
            await self.resetMPINViewModel.registerResetMPIN()
        }
    }
        
    private func bindViewModel() {
        
        self.resetMPINViewModel.onResetMPINValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
                
            case .newMPIN:
                self.newMPINTextFieldView.showError(message: error.message)
            default:
                break
            }
        }
        
        self.resetMPINViewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.resetMPINButton.isEnabled = !isLoading
            self.resetMPINButton.alpha = isLoading ? 0.6 : 1.0
        }
        
        self.resetMPINViewModel.onResetMPINError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.resetMPINViewModel.onResetMPINSuccess = { [weak self] successMsg in
            guard let self = self else { return }
            MessageManager.shared.show(message: successMsg.message, type: .success)
            self.onResetSuccess?()
        }
    }
}




extension ResetMPINViewController {
    
    private func resetMPINScreenUI() {
        
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.resetMPINTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.resetMPINButton.setTitle(APPConstants.resetMPINTitle, for: .normal)
        self.resetMPINButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.resetMPINButton.setTitleColor(.white, for: .normal)
        self.resetMPINButton.backgroundColor = .pinkPrimaryColor
        self.resetMPINButton.layer.cornerRadius = 25
        
        self.newMPINTextFieldView.customTextField.delegate = self
        self.newMPINTextFieldView.customTextField.setPlaceholder(text: APPConstants.newMPINPlaceholder)
        self.newMPINTextFieldView.placeHolderLabel.text = APPConstants.newMPINTitle
        self.newMPINTextFieldView.customTextField.tag = 0
        
        [self.newMPINTextFieldView.customTextField].forEach { textField in
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

extension ResetMPINViewController: UITextFieldDelegate {
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
            
        case 0:
            self.newMPINTextFieldView.hideError()
            
        default:
            break
        }
    }
    
    private func clearAllErrors() {
        self.newMPINTextFieldView.hideError()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.newMPINTextFieldView.customTextField {
            
            return string.checkForNumberCount(
                charsLimit: 4,
                textField: textField,
                range: range
            )
        }
        
        return true
    }
}

protocol ResetMPINDelegate: AnyObject {
    func  mpinResetSuccessfully()
}
