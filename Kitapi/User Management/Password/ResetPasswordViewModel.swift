//
//  ResetPasswordViewModel.swift
//  Kitapi
//
//  Created by Suneel on 24/04/26.
//

import Foundation

class ResetPasswordViewModel {
    
    var emailToResetPassword: String = ""
   
    var onLoadingChanged: ((Bool) -> Void)?
    var onErrorToResetPassword: ((String) -> Void)?
    var onSuccessToResetPassword: ((ForgotPasswordResponse) -> Void)?
    var onValidationErrorInEmailField: ((ValidationError) -> Void)?
    
    let resetPasswordService = PasswordService()
    
    private func validateEmailField() -> Result<Void, ValidationError> {
       
        if self.emailToResetPassword.isEmpty {
            return .failure(ValidationError(field: .emailField, message: "Email is required"))
        }
        if !self.emailToResetPassword.isValidEmail() {
            return .failure(ValidationError(field: .emailField, message: "Invalid email format"))
        }
        return .success(())
    }
    
    func sendOTP() async {
       
        let validation = validateEmailField()
        
        switch validation {
        case .success:
            // Validation passed, proceed with registration
            await sendOTPToResetPassword()
            
        case .failure(let error):
            // Validation failed, notify on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onValidationErrorInEmailField?(error)
            }
            return
        }
    }
    
    private func sendOTPToResetPassword() async {
        let requestBody = SendOTPRequest(email: self.emailToResetPassword)
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await resetPasswordService.forgotPassword(sendOtpRequest: requestBody)
            
            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Registration failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Registration failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onErrorToResetPassword?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onSuccessToResetPassword?(userData)
            }
            
        } catch {
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onErrorToResetPassword?(error.localizedDescription)
            }
        }
    }
}
