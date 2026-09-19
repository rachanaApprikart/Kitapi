//
//  MPINService.swift
//  Kitapi
//
//  Created by Suneel on 04/08/26.
//

import Foundation

struct MPINService {
    
    func getMPINStatus() async throws -> APIResponse<CheckMPINStatus> {
        
        let url = MPINEndPoint.getMPINStatus.getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func createMpin(with mpin: String) async throws -> APIResponse<MPINResponse> {
        
        let url = MPINEndPoint.createMPIN.getFullPath()
        
        let requestBody: [String: String] = ["mpin": mpin]
        
        guard let data = requestBody.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func enableChildMode(request: EnableChildModeRequest) async throws -> APIResponse<EnableChildModeResponse> {
        
        let url = MPINEndPoint.enableChildModeWithMPIN.getFullPath()
                
        guard let data = request.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func disableChildMode(request: DisableChildModeRequest) async throws -> APIResponse<DisableChildModeResponse> {
        
        let url = MPINEndPoint.disableChildModeWithMPIN.getFullPath()
                
        guard let data = request.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
}

enum MPINEndPoint {
    
    case getMPINStatus
    case createMPIN
    case enableChildModeWithMPIN
    case disableChildModeWithMPIN
    
    private func getURLPath() -> String {
        switch self {
            
        case .getMPINStatus:
            return "/api/child-mode/parent/mpin/status"
            
        case .createMPIN:
            return "/api/child-mode/parent/mpin/setup"
            
        case .enableChildModeWithMPIN:
            return "/api/child-mode/enable"
            
        case .disableChildModeWithMPIN:
            return "/api/child-mode/disable"
            
        }
    }
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
