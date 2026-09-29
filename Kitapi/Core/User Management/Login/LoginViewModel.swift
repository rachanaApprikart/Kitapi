//
//  LoginViewModel.swift
//  Kitapi
//
//  Created by Suneel on 23/04/26.
//

import Foundation


class LoginViewModel {
    
    var loginEmail: String = ""
    var loginPassword: String = ""
    var deviceVersion: String = ""
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onLoginError: ((String) -> Void)?
    var onLoginSuccess: ((LoginResponse) -> Void)?
    var onGetParentDetailsSuccess: ((ParentDetails) -> Void)?
    var onLoginValidationError: ((ValidationError) -> Void)?
    
    let loginService = LoginService()
    
    func validateLoginInputs() -> Result<Void, ValidationError> {
      
        if loginEmail.isEmpty {
            return .failure(ValidationError(field: .emailField, message: "Email is required"))
        }
        if !loginEmail.isValidEmail() {
            return .failure(ValidationError(field: .emailField, message: "Invalid email format"))
        }
        if loginPassword.isEmpty {
            return .failure(ValidationError(field: .passwordField, message: "Password is required"))
        }
        return .success(())
    }
    
    func register() async {
        let validation = validateLoginInputs()
        
        switch validation {
        case .success:
            await performLogin()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onLoginValidationError?(error)
            }
            return
        }
    }
    
    private func performLogin() async {
       
        let requestBody = LoginRequest(
            email: self.loginEmail,
            password: self.loginPassword,
            fcmToken: "emNDa2uvS7eCNtbs3VieJq:APA91bEiPapQi8VJTUHKXYneR6Z3Ot2pPVlhHns9FGV2n3rpGdiJ2Y9incMPN6F8HWU20dwAHLGCncym6YX6iPYpO_xHaEVM2NYg0EZ2oim8e0KK0CUnUy4",
            deviceType: "iOS", deviceVersion: self.deviceVersion)
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await loginService.loginUser(loginRequest: requestBody)
            
            guard response.data?.success ?? false, let loginResponse = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Login failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Login failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onLoginError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onLoginSuccess?(loginResponse)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onLoginError?(error.localizedDescription)
            }
        }
    }
    
     func getParentDetails() async {
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await loginService.getParentDetails()
            
            guard response.data?.success ?? false, let parentDetails = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to retrieve"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Unable to retrieve"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onLoginError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetParentDetailsSuccess?(parentDetails)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onLoginError?(error.localizedDescription)
            }
        }
    }
}
