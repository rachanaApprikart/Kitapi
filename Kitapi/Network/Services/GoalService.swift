//
//  GoalService.swift
//  Kitapi
//
//  Created by Suneel on 26/08/26.
//

import Foundation

struct GoalService {
    
    func getAvailableChoresForGoals(childID: String) async throws -> APIResponse<AvailableChoresResponse> {
        
        let url = GoalsEndPoint.getAvailableChores(childID: childID).getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func createGoalRequest(request: CreateGoalRequest) async throws -> APIResponse<GoalResponse> {
        
        let url = GoalsEndPoint.createGoal.getFullPath()
        
        guard let data = request.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data)
    }
    
    func getAllGoals(request: GetAllGoalsRequest, childId: String) async throws -> APIResponse<GetAllGoalResponse> {
        
        var url = GoalsEndPoint.listGoals(childID: childId).getFullPath()
        
        let parameters: [String: String] = [
            "page": request.page,
            "limit": request.limit,
            "status": request.status.rawValue,
            "type": request.type.rawValue,
            "sortOrder": request.sortOrder
        ]
        
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let urlwithQueryItems = url.queryString(params: parameters) else {
            return await APIClient.callAPIWithRawData(url: url, method: .get)
        }
        url = urlwithQueryItems
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func getGoalDetails(goalId: String) async throws -> APIResponse<GetGoalDetailsResponse> {
        let url = GoalsEndPoint.getGoalDetails(goalID: goalId).getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .get)
    }
    
    func updateGoalByAssigningTask(request: [String], goalId: String) async throws -> APIResponse<GoalUpdateResponse> {
        
        let url = GoalsEndPoint.updateGoalByAssigningChores(goalID: goalId).getFullPath()
        
        let parameters: [String: Any] = [
            "taskIds": request
        ]
        return await APIClient.callAPIWithFormData(url: url, method: .put, parameters: parameters)
    }
    
    func updateGoalStatus(request: UpdateGoalStatusRequest) async throws -> APIResponse<UpdateGoalStatusResponse> {
        
        let url = GoalsEndPoint.updateGoalStatus.getFullPath()
        
        guard let data = request.toData() else {
            LogFile.debugMessage(debug: "Encoding Error", value: "Failed to encode UpdateGoalStatusRequest")
            return APIResponse(data: nil, error: .decodingFailed, statusCode: nil) // or a dedicated .encodingFailed case
        }
        
        return await APIClient.callAPIWithRawData(url: url, method: .put, body: data)
    }
}

enum GoalsEndPoint {
    
    case getAvailableChores(childID: String)
    case createGoal
    case listGoals(childID: String)
    case getGoalDetails(goalID: String)
    case updateGoalByAssigningChores(goalID: String)
    case updateGoalStatus
    
    private func getURLPath() -> String {
        
        switch self
        {
        case .getAvailableChores(let childID):
            return "/api/goal/available_chores/\(childID)"
            
        case .createGoal:
            return "/api/goal/create_goal"
            
        case .listGoals(let childID):
            return "/api/goal/list_goal/\(childID)"
            
        case .getGoalDetails(let goalId):
            return "/api/goal/get_goal/\(goalId)"
            
        case .updateGoalByAssigningChores(let gID):
            return "/api/goal/update_goal/\(gID)"
            
        case .updateGoalStatus:
            return "/api/goal/update_goal_status"
        }
    }
    
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
//api/goal/list_goal/2077dd5f-6556-4aa9-99c2-cdcbf9b5fdf3?page=1&limit=5&type=all&status=all&sortOrder=ASC
