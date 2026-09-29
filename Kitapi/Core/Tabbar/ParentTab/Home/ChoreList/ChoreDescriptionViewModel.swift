//
//  ChoreDescriptionViewModel.swift
//  Kitapi
//
//  Created by Suneel on 31/07/26.
//

import Foundation

class ChoreDescriptionViewModel {
    
    var taskID: String = ""
    var childID: String = ""
    var status: ChoreStatus?
    var reason: String?
    
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onGetChoreDetailsSuccess: ((TaskDetailsResponse) -> Void)?
    var onGetChoreDetailsError: ((String) -> Void)?

    var onUpdateFailure: ((String) -> Void)?
    var onUpdateSuccess: ((ChoreStatusUpdateResponse) -> Void)?
    
    private let choreService = ChoreService()
    
    
    func getChoreDetails(choreId: String, childId: String) async {
                
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        do {
            let response = try await self.choreService.getChoreDetails(choreId: choreId, childId: childId)
            
            guard response.data?.success ?? false, let choreDetailResp = response.data  else {
                
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
                    self?.onGetChoreDetailsError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetChoreDetailsSuccess?(choreDetailResp)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetChoreDetailsError?(error.localizedDescription)
            }
        }
    }
    
     func updateChoreStatus() async {
        
        let requestBody = ChoreStatusUpdateRequest(
         taskId: self.taskID,
         childId: self.childID,
         status: self.status,
         reason: self.reason)
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {

            let response = try await self.choreService.updateStatus(request: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Chore update status failed"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Chore update status failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onUpdateFailure?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onUpdateSuccess?(userData)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onUpdateFailure?(error.localizedDescription)
            }
        }
    }
}
