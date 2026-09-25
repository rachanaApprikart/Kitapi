//
//  SelectTemplateImageViewModel.swift
//  Kitapi
//
//  Created by Suneel on 30/06/26.
//

import Foundation


class SelectTemplateImageViewModel {
        
    var onLoadingChanged: ((Bool) -> Void)?
    var onCreateTemplateError: ((String) -> Void)?
    var onCreateTemplateSuccess: ((CreateChoreTemplateResponse) -> Void)?
    
   private let templateService = ChoreTemplateService()
    
    
     func createTemplate(request: CreateChoreTemplateRequest) async {
                    
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            let response = try await templateService.createChoreTemplate(request: request)

            guard response.data?.success ?? false, let userData = response.data else {
                // API Error
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to create chore template"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to create chore template"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Registration failed"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onCreateTemplateError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateTemplateSuccess?(userData)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateTemplateError?(error.localizedDescription)
            }
        }
    }
}

