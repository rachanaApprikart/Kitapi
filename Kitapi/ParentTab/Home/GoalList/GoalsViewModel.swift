//
//  GoalsViewModel.swift
//  Kitapi
//
//  Created by Suneel on 26/08/26.
//

import Foundation

class GoalsViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onErrorToGetAllGoals: ((String) -> Void)?
    var onGetAllGoalsSuccess: ((GetAllGoalResponse, GetAllGoalResponse) -> Void)?
    
    var onUpdateGoalByAssigningTaskFailure: ((String) -> Void)?
    var onUpdateGoalByAssigningTaskSuccess: ((GoalUpdateResponse) -> Void)?
    
    private let goalService = GoalService()
    
    func fetchAllGoals(childId: String) async {
        
        let giftRequest = GetAllGoalsRequest(
            page: "1",
            limit: "100",
            type: .gift,
            status: .all,
            sortOrder: "ASC"
        )
        
        let milestoneRequest = GetAllGoalsRequest(
            page: "1",
            limit: "100",
            type: .milestone,
            status: .all,
            sortOrder: "ASC"
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            
            // Both API calls happen in parallel
            async let giftResponse = goalService.getAllGoals(
                request: giftRequest,
                childId: childId
            )
            
            async let milestoneResponse = goalService.getAllGoals(
                request: milestoneRequest,
                childId: childId
            )
            
            let (giftResult, milestoneResult) = try await (
                giftResponse,
                milestoneResponse
            )
            
            // Validate Gift response
            guard giftResult.data?.success ?? false,
                  let giftGoalList = giftResult.data else {
                let errorMessage = self.getErrorMessage(from: giftResult)
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onErrorToGetAllGoals?(errorMessage)
                }
                return
            }
            
            // Validate Milestone response
            guard milestoneResult.data?.success ?? false,
                  let milestoneGoalList = milestoneResult.data else {
                
                let errorMessage = getErrorMessage(from: milestoneResult)
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onErrorToGetAllGoals?(errorMessage)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                
                self?.onGetAllGoalsSuccess?(
                    giftGoalList,
                    milestoneGoalList
                )
            }
            
        } catch {
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onErrorToGetAllGoals?(error.localizedDescription)
            }
        }
    }
    
    private func getErrorMessage(from response: APIResponse<GetAllGoalResponse>) -> String {
        
        if let apiError = response.error {
            
            switch apiError {
                
            case .apiError(let errorResponse):
                return errorResponse.message ?? "Unable to retrieve"
                
            case .requestFailed(let error):
                return error.localizedDescription
                
            case .authenticationFailed(let errorResponse):
                return errorResponse.message ?? "Unable to retrieve"
                
            default:
                return "Something went wrong"
            }
        }
        
        return "Unable to retrieve"
    }
    
    func updateByAssigningTask(id: [String], goalId: String) async {
       
       // Show loading
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       
       do {

           let response = try await self.goalService.updateGoalByAssigningTask(request: id, goalId: goalId)
           
           // Validate response
           guard response.data?.success ?? false, let userData = response.data else {
               // API Error
               let errorMessage: String
               
               if let apiError = response.error {
                   switch apiError {
                   case .apiError(let errorResponse):
                       errorMessage = errorResponse.message ?? "Chore update status failed"
                       
                   case .requestFailed(let error):
                       errorMessage = error.localizedDescription
                       
                   default:
                       errorMessage = "Something went wrong"
                   }
               } else {
                   errorMessage = response.data?.message ?? "Chore update status failed"
               }
               
               DispatchQueue.main.async { [weak self] in
                   self?.onLoadingChanged?(false)
                   self?.onUpdateGoalByAssigningTaskFailure?(errorMessage)
               }
               return
           }
           
           // Success
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onUpdateGoalByAssigningTaskSuccess?(userData)
           }
           
       } catch {
           // Network/Unknown Error
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onUpdateGoalByAssigningTaskFailure?(error.localizedDescription)
           }
       }
   }
}

enum GoalsSection: Int, CaseIterable {
    case gifts
    case milestones
}

//let response = try await choreService.getChoreDetails(request: requestBody)
//
//This is the straightforward pattern:
//
//Call the async function
//await suspends the current task until it finishes
//try propagates any thrown error up to the enclosing do/catch

//async let giftResponse = goalService.getAllGoals(request: giftRequest, childId: childId)
//async let milestoneResponse = goalService.getAllGoals(request: milestoneRequest, childId: childId)
//
//let (giftResult, milestoneResult) = try await (giftResponse, milestoneResponse)
//
//This is a different mechanism than a plain await:
//
//async let starts the async operation immediately, right when that line executes — it doesn't wait. Think of it as "kick off this work in the background, I'll collect the result later." Both giftResponse and milestoneResponse start running at essentially the same time, concurrently, on child tasks.
//Nothing is actually awaited yet at that point — giftResponse and milestoneResponse are more like "handles" to eventual results.
//try await (giftResponse, milestoneResponse) is where the function actually pauses — it waits for both to complete, and unwraps the results into giftResult and milestoneResult. If either throws, the try propagates that error.


//let giftResult = try await goalService.getAllGoals(request: giftRequest, childId: childId)
//let milestoneResult = try await goalService.getAllGoals(request: milestoneRequest, childId: childId)
//
//that would be sequential — same pattern as fetchAllChores — and slower, since the second call wouldn't start until the first fully finished.
