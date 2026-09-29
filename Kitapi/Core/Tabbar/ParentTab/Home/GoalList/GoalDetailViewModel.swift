//
//  GoalDetailViewModel.swift
//  Kitapi
//
//  Created by Suneel on 31/08/26.
//

import Foundation


class GoalDetailViewModel {
    
    var goalID: String = ""
    var childID: String = ""
    var status: ChoreStatus?
    var reason: String?

    var onLoadingChanged: ((Bool) -> Void)?
    var onGetGoalDetailError: ((String) -> Void)?
    var onGetGoalDetailSuccess: ((GetGoalDetailsResponse) -> Void)?
    
    var onGoalStatusUpdateFailure: ((String) -> Void)?
    var onGoalStatusUpdateSuccess: ((UpdateGoalStatusResponse) -> Void)?
    
    private let goalService = GoalService()
    
    
    func getGoalDetails(goalId: String) async {
                
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        do {
            let response = try await goalService.getGoalDetails(goalId: goalId)
            
            guard response.data?.success ?? false, let goalDetailResp = response.data  else {
                
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
                    errorMessage = "Unable to retrieve"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onGetGoalDetailError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetGoalDetailSuccess?(goalDetailResp)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetGoalDetailError?(error.localizedDescription)
            }
        }
    }
    
    func updateGoalStatus() async {
       
       let requestBody = UpdateGoalStatusRequest(
        goalId: self.goalID,
        childId: self.childID,
        status: self.status, rejectedReason: self.reason)
   
        
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       
       do {

           let response = try await self.goalService.updateGoalStatus(request: requestBody)
           
           // Validate response
           guard response.data?.success ?? false, let userData = response.data else {
               // API Error
               let errorMessage: String
               
               if let apiError = response.error {
                   switch apiError {
                   case .apiError(let errorResponse):
                       errorMessage = errorResponse.message ?? "Goal update status failed"
                       
                   case .requestFailed(let error):
                       errorMessage = error.localizedDescription
                       
                   default:
                       errorMessage = "Something went wrong"
                   }
               } else {
                   errorMessage = response.data?.message ?? "Goal update status failed"
               }
               
               DispatchQueue.main.async { [weak self] in
                   self?.onLoadingChanged?(false)
                   self?.onGoalStatusUpdateFailure?(errorMessage)
               }
               return
           }
           
           // Success
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGoalStatusUpdateSuccess?(userData)
           }
           
       } catch {
           // Network/Unknown Error
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGoalStatusUpdateFailure?(error.localizedDescription)
           }
       }
   }
}
