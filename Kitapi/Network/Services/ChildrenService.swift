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
    
    func updateChildProfile(request: ChildProfileRequest, childId: String) async throws -> APIResponse<UpdateChildProfileResponse> {
        
        let url = ChildProfileEndPoint.updateChild(childId: childId).getFullPath()
        
        let parameters: [String: Any] = [
            "name": request.name,
            "dateOfBirth": request.dateOfBirth,
            "gender": request.gender,
            "profilePicture": request.profilePicture as Any
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .put, parameters: parameters)
    }
    
    func deleteChildProfile(childId: String) async throws -> APIResponse<DeleteChildProfileResponse> {
        
        var url = ChildProfileEndPoint.deleteChild.getFullPath()
        
        let parameters: [String: String] = [
            "childId": childId
        ]
        
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let urlwithQueryItems = url.queryString(params: parameters) else {
            return await APIClient.callAPIWithRawData(url: url, method: .delete)
        }
        url = urlwithQueryItems
        return await APIClient.callAPIWithRawData(url: url, method: .delete)
    }
}


enum ChildProfileEndPoint {
    
    case getChildren
    case createChild
    case updateChild(childId: String)
    case deleteChild
    
    private func getURLPath() -> String {
        switch self {
            
        case .getChildren:
            return "/api/parent/get_all/child"
            
        case .createChild:
            return "/api/parent/create/children"
            
        case .updateChild(let childId):
            return "/api/parent/update/child_detail/\(childId)"
            
        case .deleteChild:
            return "/api/parent/delete/child_account"
            
        }
    }
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
//api/parent/delete/child_account?childId=9c160e3d-3535-41d8-9bbd-f5451a120cf6
