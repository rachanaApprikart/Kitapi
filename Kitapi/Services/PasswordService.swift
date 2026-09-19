//
//  PasswordService.swift
//  Kitapi
//
//  Created by Suneel on 24/04/26.
//

import Foundation

struct PasswordService {
    
    func forgotPassword(sendOtpRequest: SendOTPRequest) async throws -> APIResponse<ForgotPasswordResponse> {
        
        let url = RegisterEndPoint.forgotPassword.getFullPath()
        
        guard let data = sendOtpRequest.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func resetPassword(resetPasswordReq: ResetPasswordRequest) async throws -> APIResponse<ResetPasswordResponse> {
        
        let url = RegisterEndPoint.resetPassword.getFullPath()
        
        guard let data = resetPasswordReq.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
}
