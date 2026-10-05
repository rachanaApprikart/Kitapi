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
  
    var onDeleteUserError: ((String) -> Void)?
    var onDeleteUserSuccess: ((LogoutResponse) -> Void)?
  
    private let registrationService = RegistrationService()
        
     func performLogout() async {
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await registrationService.logoutUser()
            
            guard response.data?.success ?? false, let logoutResp = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Logout failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(_):
                        DispatchQueue.main.async { [weak self] in
                            self?.onLoadingChanged?(false)
                        }
                        return
                        
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
                self?.onLogoutSuccess?(logoutResp)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onLogoutError?(error.localizedDescription)
            }
        }
    }
    
    func deleteUser() async {
       
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       
       do {
           // Make async API call
           let response = try await registrationService.deleteUser()
           
           guard response.data?.success ?? false, let deleteResp = response.data else {
               // API Error
               let errorMessage: String
               
               if let apiError = response.error {
                   switch apiError {
                   case .apiError(let errorResponse):
                       errorMessage = errorResponse.message ?? "Delete user failed"
                       
                   case .requestFailed(let error):
                       errorMessage = error.localizedDescription
                       
                   case .authenticationFailed(_):
                       DispatchQueue.main.async { [weak self] in
                           self?.onLoadingChanged?(false)
                       }
                       return
                       
                   default:
                       errorMessage = "Something went wrong"
                   }
               } else {
                   errorMessage = response.data?.message ?? "Delete user failed"
               }
               
               DispatchQueue.main.async { [weak self] in
                   self?.onLoadingChanged?(false)
                   self?.onDeleteUserError?(errorMessage)
               }
               return
           }
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onDeleteUserSuccess?(deleteResp)
           }
           
       } catch {
           // Network/Unknown Error
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onDeleteUserError?(error.localizedDescription)
           }
       }
   }
}
