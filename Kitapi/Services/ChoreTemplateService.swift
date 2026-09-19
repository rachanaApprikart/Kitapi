//
//  ChoreTemplateService.swift
//  Kitapi
//
//  Created by Suneel on 23/06/26.
//

import Foundation

struct ChoreTemplateService {
    
    func getChoreTemplates(page: String, limit: String) async throws -> APIResponse<ChoreTemplateResponse> {
        
        var url = ChoreTemplateEndPoint.getTemplates.getFullPath()
        
        let parameters: [String: String] = [
            "page": page,
            "limit": limit
        ]
        
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let urlwithQueryItems = url.queryString(params: parameters) else {
            return await APIClient.callAPIWithRawData(url: url, method: .get)
        }
        url = urlwithQueryItems
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func createChoreTemplate(request: CreateChoreTemplateRequest) async throws -> APIResponse<CreateChoreTemplateResponse> {
        
        let url = ChoreTemplateEndPoint.createTemplate.getFullPath()
        
        let parameters: [String: Any] = [
            "title": request.title,
            "image": request.image
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .post, parameters: parameters)
    }
}

enum ChoreTemplateEndPoint {
    
    case getTemplates
    case createTemplate
    
    private func getURLPath() -> String {
        switch self {
            
        case .getTemplates:
            return "/api/task/get_all_task_template"
            
        case .createTemplate:
            return "/api/task/create_task_template"
        }
    }
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
