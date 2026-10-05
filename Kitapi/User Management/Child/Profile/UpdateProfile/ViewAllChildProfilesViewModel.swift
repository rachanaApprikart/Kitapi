//
//  ViewAllChildProfilesViewModel.swift
//  Kitapi
//
//  Created by Suneel on 04/10/26.
//

import Foundation


class ViewAllChildProfilesViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onGetChildDetailsError: ((String) -> Void)?
    var onGetChildDetailsSuccess: ((ChildrenDetails) -> Void)?
    
    private let childrenService = ChildrenService()

     func getDetailsOfChildren() async {
     
        let requestBody = ChildrenDetailsRequest(page: "0", limit: "10", sortOrder: "ASC")
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await childrenService.getChildrenDetails(request: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let childDetails = response.data  else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to retrieve"
                        
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
                    errorMessage = "Unable to retrieve"
                }
            
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onGetChildDetailsError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetChildDetailsSuccess?(childDetails)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetChildDetailsError?(error.localizedDescription)
            }
        }
    }
}

