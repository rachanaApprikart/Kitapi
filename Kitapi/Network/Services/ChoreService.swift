//
//  ChoreService.swift
//  Kitapi
//
//  Created by Suneel on 18/07/26.
//

import Foundation

struct ChoreService {
    
    func createChoreRequest(request: CreateChoreRequest) async throws -> APIResponse<CreateChoreResponse> {
        
        let url = ChoreEndPoint.createChore.getFullPath()
        
        guard let data = request.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func createChoreWithAudio(request: CreateChoreAudioRequest) async throws -> APIResponse<CreateChoreResponse> {

        let url = ChoreEndPoint.createChore.getFullPath()

        let parameters: [String: Any] = [
            "taskTemplateId": request.taskTemplateId,
            "childId": request.childId,
            "startTime": request.startTime,
            "endTime": request.endTime,
            "recurrence": request.recurrence,
            "recurrenceDates": request.recurrenceDates,
            "audioDescription": request.audioDescriptionURL
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .post, parameters: parameters)
    }
    
    func getAllChores(request: GetAllChoresRequest) async throws -> APIResponse<GetAllChoresResponse> {
        
        var url = ChoreEndPoint.getAllChores.getFullPath()
        
        let parameters: [String: String] = [
            "page": request.page,
            "limit": request.limit,
            "status": request.status.rawValue,
            "childId": request.childId,
            "sortOrder": request.sortOrder
        ]
        
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let urlwithQueryItems = url.queryString(params: parameters) else {
            return await APIClient.callAPIWithRawData(url: url, method: .get)
        }
        url = urlwithQueryItems
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func getChoreDetails(choreId: String, childId: String) async throws -> APIResponse<TaskDetailsResponse> {
        let url = ChoreEndPoint.getChoreDetails(choreID: choreId, childId: childId).getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func updateStatus(request: ChoreStatusUpdateRequest) async throws -> APIResponse<ChoreStatusUpdateResponse>
    {
        let url = ChoreEndPoint.updateChoreStatus.getFullPath()
        
        let parameters: [String: String] = [
            "taskId": request.taskId,
            "childId": request.childId,
            "status": request.status?.rawValue ?? "",
            "reason": request.reason ?? ""
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .put, parameters: parameters)
    }
}

enum ChoreEndPoint {
    
    case createChore
    case getAllChores
    case updateChoreStatus
    case getChoreDetails(choreID: String, childId: String)
    
    private func getURLPath() -> String {
        switch self {
            
        case .createChore:
            return "/api/task/create"
            
        case .getAllChores:
            return "/api/task/list"
            
        case .updateChoreStatus:
            return "/api/task/status"
            
        case .getChoreDetails(let choreID, let childId):
            return "/api/task/get_task/\(choreID)/child/\(childId)"
        
        }
    }
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
