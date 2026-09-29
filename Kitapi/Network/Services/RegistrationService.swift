//
//  RegistrationService.swift
//  Kitapi
//
//  Created by Suneel on 14/04/26.
//

import Foundation

let BASE_URL: String = "https://kidswallet.apprikart.in"



struct RegistrationService {
    
    func register(request: RegisterRequest) async throws -> APIResponse<RegistrationResponse> {
        let url = RegisterEndPoint.createUser.getFullPath()
        
        let parameters: [String: String] = [
            "name": request.name,
            "countryCode": request.countryCode,
            "phone": request.phone ?? "",
            "gender": request.gender,
            "email": request.email,
            "password": request.password
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .post, parameters: parameters)
    }
    
    //20-4
    
    func requestForOTP(submitOTPRequest: SendOTPRequest) async throws -> APIResponse<SendOTPResponse> {
        
        let url = RegisterEndPoint.generateOtp.getFullPath()
        
        guard let data = submitOTPRequest.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    //21-4
    
    func verifyOTP(verifyOTPRequest: VerifyOTPRequest) async throws -> APIResponse<VerificationResponse> {
        
        let url = RegisterEndPoint.verifyUser.getFullPath()
        
        guard let data = verifyOTPRequest.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func getParentDetails() async throws -> APIResponse<ParentDetails> {
        
        let url = RegisterEndPoint.getParentDetails.getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
}

enum RegisterEndPoint {
    
    case createUser
    case generateOtp
    case verifyUser
    case login
    case forgotPassword
    case resetPassword
    case googleLogin
    case updateUser
    case getParentDetails
    
    
    private func getURLPath() -> String {
        switch self {
            
        case .createUser:
            return "/api/parent/auth/signup"
        
        case .generateOtp:
            return "/api/parent/auth/send-otp"
            
        case .verifyUser:
            return "/api/parent/auth/verify-otp"
            
        case .login:
            return "/api/parent/auth/login"
            
        case .forgotPassword:
            return "/api/parent/forgot-password"
            
        case .resetPassword:
            return "/api/parent/reset-password"
            
        case .updateUser:
            return "/api/v1/user/updateUser"
            
        case .googleLogin:
            return "/api/parent/auth/google_signin"
            
        case .getParentDetails:
            return "/api/parent/detail"
            
        }
    }
    
    
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
