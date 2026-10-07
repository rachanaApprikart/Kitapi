//
//  UpdateMPINViewModel.swift
//  Kitapi
//
//  Created by Suneel on 01/10/26.
// 05-10

import Foundation

class UpdateMPINViewModel {
    
    var currentMPIN: String = ""
    var newMPIN: String = ""
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onChangeMPINError: ((String) -> Void)?
    var onChangeMPINESuccess: ((MPINResponse) -> Void)?
    var onChangeMPINValidationError: ((ValidationError) -> Void)?

    let mpinService = MPINService()
    
    func validateChangeMPINInputs() -> Result<Void, ValidationError> {
      
        if currentMPIN.isEmpty {
            return .failure(ValidationError(field: .currentMPIN, message: APPConstants.currentMPINPlaceholder))
        }
        if newMPIN.isEmpty {
            return .failure(ValidationError(field: .newMPIN, message: APPConstants.newMPINPlaceholder))
        }
        return .success(())
    }
    
    func registerChangeMPIN() async {
        let validation = self.validateChangeMPINInputs()
        
        switch validation {
            
        case .success:
            await self.changeMPIN()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onChangeMPINValidationError?(error)
            }
            return
        }
    }
    
    private func changeMPIN() async {
       
        let requestBody = ChangeMPINRequest(currentMpin: self.currentMPIN, newMpin: self.newMPIN)
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await mpinService.changeMPINRequest(request: requestBody)
            
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
                    self?.onChangeMPINError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onChangeMPINESuccess?(mpinResponse)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onChangeMPINError?(error.localizedDescription)
            }
        }
    }
}
