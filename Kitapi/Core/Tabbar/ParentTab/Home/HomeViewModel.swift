//
//  HomeViewModel.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import Foundation


class HomeViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onChildDetailsSuccess: ((ChildrenDetails) -> Void)?
    
    var onCheckMPINStatusSuccess: ((CheckMPINStatus) -> Void)?
    var onCheckMPINStatusError: ((String) -> Void)?

    private let childrenService = ChildrenService()
    private let mpinService = MPINService()

    
     func getDetailsOfChildren() async {
     
        let requestBody = ChildrenDetailsRequest(page: "0", limit: "10", sortOrder: "ASC")
        
        // Show loading
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
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = "Unable to retrieve"
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
                self?.onChildDetailsSuccess?(childDetails)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onError?(error.localizedDescription)
            }
        }
    }
    
    
    
    func checkMPINStatus() async {
           
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       do {
           let response = try await mpinService.getMPINStatus()
           
           guard response.data?.success ?? false, let mpinDetails = response.data  else {

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
                   self?.onCheckMPINStatusError?(errorMessage)
               }
               return
           }
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onCheckMPINStatusSuccess?(mpinDetails)
           }
       } catch {
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onCheckMPINStatusError?(error.localizedDescription)
           }
       }
   }
}

