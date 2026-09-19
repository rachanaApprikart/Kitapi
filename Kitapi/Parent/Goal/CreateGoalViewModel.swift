//
//  CreateGoalViewModel.swift
//  Kitapi
//
//  Created by Suneel on 27/08/26.
//

import Foundation

class CreateGoalViewModel {
    
    var giftName: String = ""
    var childId: String = ""
    var goalDescription: String = ""
    
    var goalType: GoalType = .milestone
    var taskIds: [String] = []
    var milestoneAmt: Int?
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onCreateGoalError: ((String) -> Void)?
    var onCreateGoalSuccess: ((GoalResponse) -> Void)?
    var onValidationError: ((ValidationError) -> Void)?
    
    private let goalService = GoalService()
    
    private func validateInputs() -> Result<Void, ValidationError> {
        
        switch self.goalType {
            
        case .gift:
            if self.giftName.isEmpty {
                return .failure(ValidationError(field: .giftName, message: "Gift name is required"))
            }
            
        case .milestone:
            break
        case .all:
            break
        }
        return .success(())
    }
    
    func register() async {
        
        let validation = self.validateInputs()
        
        switch validation {
        case .success:
            await self.createGoal()
            
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onValidationError?(error)
            }
            return
        }
    }
    
    private func createGoal() async {
        
        let requestBody: CreateGoalRequest

        switch self.goalType {
            
        case .gift:
            
            requestBody = CreateGoalRequest(
                title: self.giftName,
                description: self.goalDescription,
                childId: self.childId,
                goalType: self.goalType.rawValue,
                taskIds: self.taskIds,
                milestoneAmount: nil)
            
        case .milestone:
            
            requestBody = CreateGoalRequest(
                title: APPConstants.earnCoinsGoalTitle,
                description: self.goalDescription,
                childId: self.childId,
                goalType: self.goalType.rawValue,
                taskIds: nil,
                milestoneAmount: self.milestoneAmt)
            
        case .all:
            requestBody = CreateGoalRequest(
                title: "",
                description: "",
                childId: "",
                goalType: "",
                taskIds: nil,
                milestoneAmount: nil)
        }

        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await goalService.createGoalRequest(request: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Goal creation failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Goal creation failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onCreateGoalError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateGoalSuccess?(userData)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateGoalError?(error.localizedDescription)
            }
        }
    }
}
