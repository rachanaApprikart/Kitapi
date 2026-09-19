//
//  ChildrenService.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import Foundation


struct ChildrenService {
    
    func getChildrenDetails(request: ChildrenDetailsRequest) async throws -> APIResponse<ChildrenDetails> {
        
        var url = ChildProfileEndPoint.getChildren.getFullPath()
        
        let parameters: [String: String] = [
            "page": request.page,
            "limit": request.limit,
//            "minAge": request.minAge,
//            "maxAge": request.maxAge,
            "sortOrder": request.sortOrder
        ]
        
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let urlwithQueryItems = url.queryString(params: parameters) else {
            return await APIClient.callAPIWithRawData(url: url, method: .get)
        }
        url = urlwithQueryItems
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func createChildProfile(request: ChildProfileRequest) async throws -> APIResponse<ChildProfileResponse> {
        let url = ChildProfileEndPoint.createChild.getFullPath()
        
        let parameters: [String: Any] = [
            "name": request.name,
            "dateOfBirth": request.dateOfBirth,
            "gender": request.gender,
            "profilePicture": request.profilePicture as Any
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .post, parameters: parameters)
    }
}


enum ChildProfileEndPoint {
    
    case getChildren
    case createChild
    
    private func getURLPath() -> String {
        switch self {
            
        case .getChildren:
            return "/api/parent/get_all/child"
            
        case .createChild:
            return "/api/parent/create/children"
        }
    }
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
