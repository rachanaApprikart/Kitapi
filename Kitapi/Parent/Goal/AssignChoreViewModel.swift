//
//  AssignChoreViewModel.swift
//  Kitapi
//
//  Created by Suneel on 26/08/26.
//

import Foundation

class AssignChoreViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onGetAvailableChoresError: ((String) -> Void)?
    var onGetAvailableChoresSuccess: ((AvailableChoresResponse) -> Void)?
    
    private let goalService = GoalService()
    
    
    func getAvailableChores(childId: String) async {
                
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        do {
            let response = try await goalService.getAvailableChoresForGoals(childID: childId)
            
            guard response.data?.success ?? false, let availChoreResp = response.data  else {
                
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to retrieve"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to retrieve"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = "Unable to retrieve"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onGetAvailableChoresError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetAvailableChoresSuccess?(availChoreResp)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetAvailableChoresError?(error.localizedDescription)
            }
        }
    }
}
