//
//  ChildProfileViewModel.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import Foundation
import UIKit

//18-05

class ChildProfileViewModel {
    
    var childName: String = ""
    var childGender: String = ""
    var childDob: String = ""
    var profilePicture: UIImage? = nil
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onCreateChildProfileSuccess: ((ChildProfileResponse) -> Void)?
    var onValidationError: ((ValidationError) -> Void)?
    
   private let childrenService = ChildrenService()
    
    
    private func validateInputs() -> Result<Void, ValidationError> {
        if childName.isEmpty {
            return .failure(ValidationError(field: .nameField, message: "Name is required"))
        }
        if childDob.isEmpty {
           return .failure(ValidationError(field: .dobField, message: "Date of birth is required"))
        }
        if childGender.isEmpty {
            return .failure(ValidationError(field: .genderField, message: "Gender is required"))
        }
        return .success(())
    }
    
    func register() async {
        let validation = validateInputs()
        
        switch validation {
        case .success:
            await createChildProfile()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onValidationError?(error)
            }
            return
        }
    }
    
    private func createChildProfile() async {
        let requestBody = ChildProfileRequest(
            name: childName,
            dateOfBirth: childDob,
            gender: childGender,
            profilePicture: profilePicture)
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await childrenService.createChildProfile(request: requestBody)
            

            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Registration failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Registration failed"
                        
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
                self?.onCreateChildProfileSuccess?(userData)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onError?(error.localizedDescription)
            }
        }
    }
}



