//
//  CreateChoreViewModel.swift
//  Kitapi
//
//  Created by Suneel on 18/07/26.
//

import Foundation


class CreateChoreViewModel {
    
    var choreTemplateId: String = ""
    var childId: String = ""
    var choreDescription: String = ""
    var startTime: String = ""
    var endTime: String = ""
    var recurrence: String = ""
    var recurrenceDates: [String] = []
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onCreateChoreError: ((String) -> Void)?
    var onCreateChoreSuccess: ((CreateChoreResponse) -> Void)?
    var onValidationError: ((ValidationError) -> Void)?
    
   private let choreService = ChoreService()
    
    private func validateInputs() -> Result<Void, ValidationError> {
        
        if self.choreTemplateId.isEmpty {
            return .failure(ValidationError(field: .choreTitle, message: "Title is required"))
        }
        if self.choreDescription.isEmpty {
            return .failure(ValidationError(field: .choreDescription, message: "Description is required"))
        }
        return .success(())
    }
    
    func register() async {
        
        let validation = self.validateInputs()
        
        switch validation {
        case .success:
            await self.createChore()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onValidationError?(error)
            }
            return
        }
    }
    
    private func createChore() async {
        
        let requestBody = CreateChoreRequest(
            taskTemplateId: self.choreTemplateId,
            childId: self.childId,
            description: self.choreDescription,
            startTime: self.startTime,
            endTime: self.endTime,
            recurrence: self.recurrence,
            recurrenceDates: self.recurrenceDates)
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await choreService.createChoreRequest(request: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Chore creation failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Chore creation failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onCreateChoreError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateChoreSuccess?(userData)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateChoreError?(error.localizedDescription)
            }
        }
    }
}

