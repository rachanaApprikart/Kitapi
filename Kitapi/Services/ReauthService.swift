//
//  ReauthService.swift
//  Kitapi
//
//  Created by Suneel on 09/09/26.
//

import Foundation


struct ChildModeService {
    
    func parentReauth(request: ParentReauthRequest) async -> APIResponse<ParentReauthResponse> {
        
        let url = ChildModeEndPoint.parentReauth.getFullPath()
       
        guard let data = request.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data, tokenScope: .parent)
    }
}



enum ChildModeEndPoint {
    case parentReauth
    
    private func getURLPath() -> String {
        switch self {
        case .parentReauth:
            return "/api/child-mode/parent/reauth"
        }
    }
    
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
