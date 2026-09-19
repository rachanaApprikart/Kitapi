//
//  ReAuthViewModel.swift
//  Kitapi
//
//  Created by Suneel on 06/09/26.
//

import Foundation


class ReAuthViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onReauthError: ((String) -> Void)?
    var onReauthSuccess: ((ParentReauthResponse) -> Void)?
    
    
    private let childModeService = ChildModeService()
    
    func reauthenticate(mpin: String) async {
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        let request = ParentReauthRequest(authMethod: "mpin", mpin: mpin)
        
        let response = await childModeService.parentReauth(request: request)
        
        guard response.data?.success ?? false, let reauthResp = response.data else {
            
            let errorMessage: String
            
            if let apiError = response.error {
                switch apiError {
                case .apiError(let errorResponse):
                    errorMessage = errorResponse.message ?? "Failed to reauthenticate"
                case .requestFailed(let error):
                    errorMessage = error.localizedDescription
                case .authenticationFailed:
                    errorMessage = "Incorrect MPIN"
                default:
                    errorMessage = "Something went wrong"
                }
            } else {
                errorMessage = "Failed to reauthenticate"
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onReauthError?(errorMessage)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(false)
            self?.onReauthSuccess?(reauthResp)
        }
    }
}

protocol ReAuthDelegate: AnyObject {
    func didFailReauth(message: String)
    func didReauthSuccessfully()
}
