//
//  OTPTextField.swift
//  Kitapi
//
//  Created by Suneel on 06/04/26.
//

import UIKit

class OTPTextField: UITextField {
    
    var normalBorderColor: UIColor = UIColor.borderColor {
        didSet {
            if !isFirstResponder && !isErrorState {
                layer.borderColor = normalBorderColor.cgColor
            }
        }
    }
    
    var activeBorderColor: UIColor = UIColor.pinkPrimaryColor {
        didSet {
            self.updateBorderColor()
        }
    }
    
    var errorBorderColor: UIColor = .errorColor {
        didSet {
            if isErrorState {
                layer.borderColor = errorBorderColor.cgColor
            }
        }
    }
    
    var isErrorState: Bool = false {
        didSet {
            self.updateBorderColor()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setup()
    }
    
    private func setup() {
        self.textAlignment = .center
        self.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.textColor = .textColor
        self.backgroundColor = .white
        
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 0.5
        self.layer.borderColor = normalBorderColor.cgColor
        
        self.keyboardType = .numberPad
        
        // Limit to 1 character
        self.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    @objc private func textDidChange() {
        if let text = text, text.count > 1 {
            self.text = String(text.prefix(1))
        }
    }
    
    private func updateBorderColor() {
        if isErrorState {
            layer.borderColor = errorBorderColor.cgColor
            layer.borderWidth = 0.5
        } else if isFirstResponder {
            layer.borderColor = activeBorderColor.cgColor
            layer.borderWidth = 1
        } else {
            layer.borderColor = normalBorderColor.cgColor
            layer.borderWidth = 0.5
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        updateBorderColor()
        return result
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        updateBorderColor()
        return result
    }
    
    // Handle delete/backspace
    override func deleteBackward() {
        super.deleteBackward()
        
        // Notify parent view to move to previous field
        if text?.isEmpty ?? true {
            sendActions(for: .editingChanged)
        }
    }
}



