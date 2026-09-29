//
//  OTPInputView.swift
//  Kitapi
//
//  Created by Suneel on 06/04/26.
//

import UIKit

class OTPInputView: UIView {
    
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var otpTextFieldView1: OTPTextField!
    @IBOutlet weak var otpTextFieldView2: OTPTextField!
    @IBOutlet weak var otpTextFieldView3: OTPTextField!
    @IBOutlet weak var otpTextFieldView4: OTPTextField!
    @IBOutlet weak var otpTextFieldView5: OTPTextField!
    @IBOutlet weak var otpTextFieldView6: OTPTextField!
    
    var textFields: [OTPTextField] = []
    var onOTPComplete: ((String) -> Void)?
    var onOTPChanged: ((String) -> Void)?
    
    var isError: Bool = false {
        didSet {
            textFields.forEach { $0.isErrorState = isError }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadFromNib()
    }
    
    private func loadFromNib() {
        Bundle.main.loadNibNamed("OTPInputView", owner: self, options: nil)
        self.addSubview(contentView)
        self.contentView.frame = bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupTextFields()
    }
    
    // MARK: - Setup
    private func setupTextFields() {
        textFields = [otpTextFieldView1, otpTextFieldView2, otpTextFieldView3, otpTextFieldView4, otpTextFieldView5, otpTextFieldView6].compactMap { $0 }
        
        for (index, textField) in textFields.enumerated() {
            textField.delegate = self
            textField.tag = index
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        
        // Auto-focus first field
        DispatchQueue.main.async {
            self.textFields.first?.becomeFirstResponder()
        }
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text,
              let index = textFields.firstIndex(of: textField as! OTPTextField) else {
            return
        }
        
        // Move to next field if digit entered
        if text.count == 1 {
            if index < textFields.count - 1 {
                self.textFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
                self.checkOTPComplete()
            }
        } else if text.isEmpty {
            // Move to previous field on delete
            if index > 0 {
                self.textFields[index - 1].becomeFirstResponder()
            }
        }
        
        // Notify on change
        onOTPChanged?(getOTP())
    }
    
    private func checkOTPComplete() {
        let otp = getOTP()
        if otp.count == 6 {
            onOTPComplete?(otp)
        }
    }
    
    // MARK: - Public Methods
    func getOTP() -> String {
        return textFields.map { $0.text ?? "" }.joined()
    }
    
    func setOTP(_ code: String) {
        let digits = Array(code.prefix(6))
        for (index, digit) in digits.enumerated() {
            if index < textFields.count {
                textFields[index].text = String(digit)
            }
        }
    }
    
    func clearOTP() {
        textFields.forEach { $0.text = "" }
        textFields.first?.becomeFirstResponder()
        isError = false
    }
}


extension OTPInputView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow backspace
        if string.isEmpty { return true }
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) else { return false }
        
//        if string.count > 1 {
//            distributeOTP(string, startingAt: textField as! OTPTextField)
//            return false
//        }
        return true
    }
    
//    private func distributeOTP(_ code: String, startingAt textField: OTPTextField) {
//          guard let startIndex = textFields.firstIndex(of: textField) else { return }
//
//          let digits = Array(code.prefix(textFields.count - startIndex))
//          for (offset, digit) in digits.enumerated() {
//              textFields[startIndex + offset].text = String(digit)
//          }
//
//          // Move focus to the next empty field, or the last filled one
//          let nextIndex = startIndex + digits.count
//          if nextIndex < textFields.count {
//              textFields[nextIndex].becomeFirstResponder()
//          } else {
//              textFields.last?.resignFirstResponder()
//          }
//
//          onOTPChanged?(getOTP())
//          checkOTPComplete()
//      }
}
