//
//  ProfileViewModel.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
// 28-09

import Foundation


class ProfileViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onLogoutError: ((String) -> Void)?
    var onLogoutSuccess: ((LogoutResponse) -> Void)?
  
    let loginService = LoginService()
        
     func performLogout() async {
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await loginService.logoutUser()
            
            guard response.data?.success ?? false, let loginResponse = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Logout failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Logout failed"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Logout failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onLogoutError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onLogoutSuccess?(loginResponse)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onLogoutError?(error.localizedDescription)
            }
        }
    }
}
