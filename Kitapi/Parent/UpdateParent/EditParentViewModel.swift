//
//  EditParentViewModel.swift
//  Kitapi
//
//  Created by Suneel on 03/10/26.
//

import Foundation
import UIKit


class EditParentViewModel {
    
    var name: String = ""
    var phone: String = ""
    var gender: String = ""
    var country: String = "India"
    var currency: String = "INR"
    var profilePicture: UIImage? = nil

    var onLoadingChanged: ((Bool) -> Void)?
    var onUpdateError: ((String) -> Void)?
    var onUpdateSuccess: ((ParentDetails) -> Void)?
    var onValidationError: ((ValidationError) -> Void)?
    
    let registrationService = RegistrationService()
    

    private func validateInputs() -> Result<Void, ValidationError> {
        
        if self.name.isEmpty {
            return .failure(ValidationError(field: .nameField, message: "Name is required"))
        }
        if gender.isEmpty {
            return .failure(ValidationError(field: .genderField, message: "Gender is required"))
        }
        return .success(())
    }
    
    func register() async {

        let validation = self.validateInputs()
        
        switch validation {
        case .success:
            await self.updateParentDetails()
            
        case .failure(let error):
            // Validation failed, notify on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onValidationError?(error)
            }
            return
        }
    }
    
    private func updateParentDetails() async {
        
        let requestBody = UpdateParentRequest(
            name: self.name,
            country: self.country,
            currency: self.currency,
            countryCode: self.phone.isEmpty ? "" : "+91",
            phone: self.phone,
            gender: self.gender,
            image: self.profilePicture)
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await registrationService.updateParentDetails(request: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Registration failed"
                        
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
                    errorMessage = response.data?.message ?? "Registration failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onUpdateError?(errorMessage)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onUpdateSuccess?(userData)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onUpdateError?(error.localizedDescription)
            }
        }
    }
}
