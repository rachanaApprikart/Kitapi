//
//  VerifyOTPViewModel.swift
//  Kitapi
//
//  Created by Suneel on 21/04/26.
//

import Foundation


class VerifyOTPViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onOTPError: ((String) -> Void)?
    var onSendOTPSuccess: ((SendOTPResponse) -> Void)?
    var onVerifyOTPSuccess: ((VerificationResponse) -> Void)?
    var onGetVerifiedParentDetailsSuccess: ((ParentDetails) -> Void)?
    
    private let otpService = RegistrationService()

    
    func submitOTPToUser(email: String) async {
        let requestBody = SendOTPRequest(email: email)
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await otpService.requestForOTP(submitOTPRequest: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let sendOTPResponse = response.data else {
                // API Error
                
                let errorMessage: String
                if let apiError = response.error {
                    switch apiError {
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to send OTP"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to send OTP"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Failed to send OTP"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onOTPError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onSendOTPSuccess?(sendOTPResponse)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onOTPError?(error.localizedDescription)
            }
        }
    }
    
    
    func verifyOTP(email: String, otp: String, version: String) async {
        
        let requestBody = VerifyOTPRequest(
            email: email,
            otp: otp,
            fcmToken: "",
            deviceType: "iOS",
            deviceVersion: version)
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await otpService.verifyOTP(verifyOTPRequest: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let verifyOTPResponse = response.data else {
               
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                  
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to verify OTP"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to verify OTP"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Failed to verify OTP"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onOTPError?(errorMessage)
                }
                return
            }
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onVerifyOTPSuccess?(verifyOTPResponse)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onOTPError?(error.localizedDescription)
            }
        }
    }
    
    func getVerifiedParentDetails() async {
       
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       
       do {
           // Make async API call
           let response = try await otpService.getParentDetails()
           
           guard response.data?.success ?? false, let parentDetails = response.data else {
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
                   errorMessage = response.data?.message ?? "Unable to retrieve"
               }
               
               DispatchQueue.main.async { [weak self] in
                   self?.onLoadingChanged?(false)
                   self?.onOTPError?(errorMessage)
               }
               return
           }
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGetVerifiedParentDetailsSuccess?(parentDetails)
           }
           
       } catch {
           // Network/Unknown Error
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onOTPError?(error.localizedDescription)
           }
       }
   }
}
