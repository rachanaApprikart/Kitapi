//
//  LoginService.swift
//  Kitapi
//
//  Created by Suneel on 23/04/26.
//

import Foundation

struct LoginService {
    
    func loginUser(loginRequest: LoginRequest) async throws -> APIResponse<LoginResponse> {
        
        let url = RegisterEndPoint.login.getFullPath()
        
        guard let data = loginRequest.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func getParentDetails() async throws -> APIResponse<ParentDetails> {
        
        let url = RegisterEndPoint.getParentDetails.getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    //Google login - use this api to share fcm token with our backend
    
    func loggedInUsingGoogle(loginRequest: GoogleLoginRequest) async throws -> APIResponse<VerificationResponse> {
        
        let url = RegisterEndPoint.googleLogin.getFullPath()
        
        guard let data = loginRequest.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
}
