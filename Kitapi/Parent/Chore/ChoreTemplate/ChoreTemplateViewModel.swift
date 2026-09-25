//
//  ChoreTemplateViewModel.swift
//  Kitapi
//
//  Created by Suneel on 23/06/26.
//

import Foundation

class ChoreTemplateViewModel {
    
    var onError: ((String) -> Void)?
    var onGetChoreTemplates: ((ChoreTemplateResponse) -> Void)?
    
    private let choreTemplateService = ChoreTemplateService()
        
    
    func getAllChoreTemplates() async {
        do {
            // Make async API call
            let response = try await choreTemplateService.getChoreTemplates(page: "1", limit: "30")
            
            // Validate response
            guard response.data?.success ?? false, let templates = response.data  else {
                // API Error
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
                    self?.onError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onGetChoreTemplates?(templates)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
