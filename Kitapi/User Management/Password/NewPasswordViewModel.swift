//
//  NewPasswordViewModel.swift
//  Kitapi
//
//  Created by Suneel on 24/04/26.
//

import Foundation

class NewPasswordViewModel {
    
    var newPassword: String = ""
    var confirmNewPassword: String = ""
    var emailToSetNewPassword: String = ""
    var otpToSetNewPassword: String = ""
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onResetNewPasswordError: ((String) -> Void)?
    var onResetNewPasswordSuccess: ((ResetPasswordResponse) -> Void)?
    var onResetNewPasswordValidationError: ((ValidationError) -> Void)?
    
    let resetPasswordService = PasswordService()
    
    private func validateResetPasswordInputs() -> Result<Void, ValidationError> {
      
        if otpToSetNewPassword.isEmpty {
            return .failure(ValidationError(field: .otpField, message: "OTP is required"))
        }
        
        if newPassword.isEmpty {
            return .failure(ValidationError(field: .passwordField, message: "Password is required"))
        }
        if newPassword.count < 6 {
            return .failure(ValidationError(field: .passwordField, message: "Password must be at least 6 characters"))
        }
        if newPassword != confirmNewPassword {
            return .failure(ValidationError(field: .confirmPasswordField, message: "Passwords do not match"))
        }
        return .success(())
    }
    
    func setNewPassword() async {
        let validation = self.validateResetPasswordInputs()
        
        switch validation {
        case .success:
            await performResettingPassword()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onResetNewPasswordValidationError?(error)
            }
            return
        }
    }
    
    private func performResettingPassword() async {
       
        let requestBody = ResetPasswordRequest(
            email: self.emailToSetNewPassword,
            otp: self.otpToSetNewPassword,
            password: newPassword)
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await resetPasswordService.resetPassword(resetPasswordReq: requestBody)
            
            guard response.data?.success ?? false, let resetPassResp = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to reset OTP"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to reset OTP"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Login failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onResetNewPasswordError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onResetNewPasswordSuccess?(resetPassResp)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onResetNewPasswordError?(error.localizedDescription)
            }
        }
    }
}
