//
//  CustomTextField.swift
//  StyleTribute
//
//  Created by Rachana on 01/04/26.
//

import UIKit

class CustomTextField: UIView {

    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var customTextField: UITextField!
    @IBOutlet weak var placeHolderLabel: UILabel!
    let dropDownBtn = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setCustomTextfieldUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setCustomTextfieldUI()
        
    }
    
    private func setCustomTextfieldUI() {
        Bundle.main.loadNibNamed("CustomTextField", owner: self, options: nil)
        self.addSubview(bgView)

        NSLayoutConstraint.activate([
                    self.bgView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
                    self.bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
                    self.bgView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
                    self.bgView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
                    ])
        
        self.customTextField.layer.cornerRadius = 15
        self.customTextField.layer.borderWidth = 0.5
        self.customTextField.layer.borderColor = UIColor.borderColor.cgColor
        self.customTextField.addPadding(.left(14))
        self.customTextField.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.customTextField.textColor = .textColor
           
        self.placeHolderLabel.textColor = .labelPlaceholderColor
        self.placeHolderLabel.textAlignment = .left
        self.placeHolderLabel.numberOfLines = 1
        self.placeHolderLabel.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        
        self.errorLabel.textColor = .errorColor
        self.errorLabel.textAlignment = .right
        self.errorLabel.numberOfLines = 1
        self.errorLabel.font = UIFont(name: Fonts.urbanistRegular, size: 14)

        self.layoutIfNeeded()
    }

//    func showPlaceholder(_ text: String?) {
//
//        if self.customTextField.isFirstResponder {
//            UIView.animate(withDuration: 0.4, delay: 0.2) {
//                self.placeHolderLabel.text = text
//            }
//        }
//    }
    
//    func hidePlaceHolder() {
//
//        if self.customTextField.isFirstResponder {
//            UIView.animate(withDuration: 0.4, delay: 0.2) {
//                self.placeHolderLabel.text = ""
//            }
//        }
//      }
    
    func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        self.customTextField.layer.borderWidth = 0.5
        self.customTextField.layer.borderColor = UIColor.errorColor.cgColor
    }
    
    func hideError() {
        if self.customTextField.isFirstResponder {
            errorLabel.isHidden = true
            errorLabel.text = ""
            self.customTextField.layer.borderWidth = 0.5
            self.customTextField.layer.borderColor = UIColor.borderColor.cgColor
        }
    }
    
    func hideErrorMessage() {
        errorLabel.isHidden = true
        errorLabel.text = ""
        self.customTextField.layer.borderWidth = 0.5
        self.customTextField.layer.borderColor = UIColor.borderColor.cgColor
    }
    
    func showRightView() {
        self.dropDownBtn.setImage(AppImages.drop_down_image, for: .normal)
        self.dropDownBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        self.customTextField.rightView = dropDownBtn
        self.customTextField.rightViewMode = .always
    }
    
    func showRightMicView() {
        self.dropDownBtn.setImage(AppImages.mic, for: .normal)
        self.dropDownBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        self.customTextField.rightView = dropDownBtn
        self.customTextField.rightViewMode = .always
    }
    
    
    func showLeftView() {
        let iconImageView = UIImageView(image: AppImages.schedule)
        
        // Container provides padding
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 24))
        iconImageView.frame = CGRect(x: 12, y: 2, width: 20, height: 20)
        containerView.addSubview(iconImageView)

        self.customTextField.leftView = containerView
        self.customTextField.leftViewMode = .always
    }
    
    func showLeftCoinImageView(coinImage: UIImage) {
        let iconImageView = UIImageView(image: coinImage)
        
        // Container provides padding
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 24))
        iconImageView.frame = CGRect(x: 12, y: 2, width: 20, height: 20)
        containerView.addSubview(iconImageView)

        self.customTextField.leftView = containerView
        self.customTextField.leftViewMode = .always
    }
    
    func showRightEyeView() {
        self.dropDownBtn.setImage(AppImages.eye_open, for: .normal)
        self.dropDownBtn.setImage(AppImages.eye_closed, for: .selected)
        self.dropDownBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
        self.customTextField.rightView = dropDownBtn
        self.customTextField.rightViewMode = .always
    }
}
