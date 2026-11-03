//
//  ResetMPINViewModel.swift
//  Kitapi
//
//  Created by Suneel on 15/10/26.
//

import Foundation


class ResetMPINViewModel {
    
    var newMPIN: String = ""
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onResetMPINError: ((String) -> Void)?
    var onResetMPINSuccess: ((MPINResponse) -> Void)?
    var onResetMPINValidationError: ((ValidationError) -> Void)?

    let mpinService = MPINService()
    
    private func validateResetMPINInputs() -> Result<Void, ValidationError> {
      
        if newMPIN.isEmpty {
            return .failure(ValidationError(field: .newMPIN, message: APPConstants.newMPINPlaceholder))
        }
        return .success(())
    }
    
    func registerResetMPIN() async {
        let validation = self.validateResetMPINInputs()
        
        switch validation {
            
        case .success:
            await self.resetMPIN()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onResetMPINValidationError?(error)
            }
            return
        }
    }
    
    private func resetMPIN() async {
               
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await mpinService.resetMPIN(with: self.newMPIN)
            
            guard response.data?.success ?? false, let mpinResponse = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Change MPIN failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Change MPIN failed"
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.onLoadingChanged?(false)
                        }
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Change MPIN failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onResetMPINError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onResetMPINSuccess?(mpinResponse)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onResetMPINError?(error.localizedDescription)
            }
        }
    }
}
