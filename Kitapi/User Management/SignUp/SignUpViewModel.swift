//
//  SignUpViewModel.swift
//  Kitapi
//
//  Created by Suneel on 14/04/26.
//

import Foundation
import UIKit

class RegisterViewModel {
    
    // MARK: - Properties
    var email: String = ""
    var password: String = ""
    var name: String = ""
    var phone: String = ""
    var gender: String = ""
    var confirmPassword: String = ""
    var profilePicture: UIImage? = nil

    // Callbacks for UIKit (always called on main thread)
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: ((User) -> Void)?
    var onValidationError: ((ValidationError) -> Void)?
    
    let registrationService = RegistrationService()
    
    //15-04
    
    private func validateInputs() -> Result<Void, ValidationError> {
        if self.name.isEmpty {
            return .failure(ValidationError(field: .nameField, message: "Name is required"))
        }
        if self.email.isEmpty {
            return .failure(ValidationError(field: .emailField, message: "Email is required"))
        }
        if !email.isValidEmail() {
            return .failure(ValidationError(field: .emailField, message: "Invalid email format"))
        }
        if gender.isEmpty {
            return .failure(ValidationError(field: .genderField, message: "Gender is required"))
        }
        //       if phone.isEmpty {
        //            return .failure(ValidationError(field: .phoneField, message: "Phone number is required"))
        //        }
        //       if !phone.isValidIndianPhone() {
        //            return .failure(ValidationError(field: .phoneField, message: "Enter valid Indian mobile number"))
        //        }
        if password.isEmpty {
           return .failure(ValidationError(field: .passwordField, message: "Password is required"))
        }
        if password.count < 6 {
            return .failure(ValidationError(field: .passwordField, message: "Password must be at least 6 characters"))
        }
        if password != confirmPassword {
            return .failure(ValidationError(field: .confirmPasswordField, message: "Passwords do not match"))
        }
        return .success(())
    }
    
    func register() async {
        // Validate inputs
        let validation = validateInputs()
        
        switch validation {
        case .success:
            // Validation passed, proceed with registration
            await performRegistration()
            
        case .failure(let error):
            // Validation failed, notify on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onValidationError?(error)
            }
            return
        }
    }
    
    private func performRegistration() async {
        let requestBody = RegisterRequest(
            name: name,
            countryCode: phone.isEmpty ? "" : "+91",
            phone: phone,
            gender: gender.lowercased(),
            email: email,
            password: password
        )
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await registrationService.register(request: requestBody, profilePicture: self.profilePicture)
            
            // Validate response
            guard response.data?.success ?? false, let userData = response.data?.user else {
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
                    self?.onError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onSuccess?(userData)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onError?(error.localizedDescription)
            }
        }
    }
}


enum ValidationField {
    case nameField
    case emailField
    case genderField
    //  case phoneField
    case passwordField
    case confirmPasswordField
    case otpField
    case dobField
    case choreTitle
    case choreDescription
    case giftName
}

struct ValidationError: Error {
    let field: ValidationField
    let message: String
}
