//
//  MPINView.swift
//  Kitapi
//
//  Created by Suneel on 04/08/26.
//

import UIKit

class MPINView: UIView {
    
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var pin1TextField: OTPTextField!
    @IBOutlet weak var pin2TextField: OTPTextField!
    @IBOutlet weak var pin3TextField: OTPTextField!
    @IBOutlet weak var pin4TextField: OTPTextField!
    
    private var textFields: [OTPTextField] = []
    var onMPINComplete: ((String) -> Void)?
    var onMPINChanged: ((String) -> Void)?
    
    var isMPINError: Bool = false {
        didSet {
            self.textFields.forEach { $0.isErrorState = isMPINError }
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupTextFields()
    }
    
    private func loadFromNib() {
        Bundle.main.loadNibNamed("MPINView", owner: self, options: nil)
        self.addSubview(contentView)
        self.contentView.frame = bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.pin1TextField.backgroundColor = .gradientColor1
        self.pin2TextField.backgroundColor = .gradientColor1
        self.pin3TextField.backgroundColor = .gradientColor1
        self.pin4TextField.backgroundColor = .gradientColor1

    }
    
    
    // MARK- Setup
    
    private func setupTextFields() {
        self.textFields = [pin1TextField, pin2TextField, pin3TextField, pin4TextField].compactMap { $0 }
        
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
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text,
              let index = textFields.firstIndex(of: textField as! OTPTextField) else {
            return
        }
        
        // Move to next field if digit entered
        if text.count == 1 {
            if index < self.textFields.count - 1 {
                self.textFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
                self.checkMPINComplete()
            }
        } else if text.isEmpty {
            // Move to previous field on delete
            if index > 0 {
                self.textFields[index - 1].becomeFirstResponder()
            }
        }
        
        // Notify on change
        self.onMPINChanged?(getMPIN())
    }
    
    private func checkMPINComplete() {
        let otp = getMPIN()
        if otp.count == 6 {
            onMPINComplete?(otp)
        }
    }
    
    // MARK: - Public Methods
    func getMPIN() -> String {
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
        self.textFields.forEach { $0.text = "" }
        self.textFields.first?.becomeFirstResponder()
        self.isMPINError = false
    }
}


extension MPINView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow backspace
        if string.isEmpty { return true }
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) else { return false }
        return true
    }
}
