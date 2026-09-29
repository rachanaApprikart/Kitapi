//
//  AnalyticsViewModel.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import Foundation

class AnalyticsViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onCheckMPINStatusSuccess: ((CheckMPINStatus) -> Void)?
    var onCheckMPINStatusError: ((String) -> Void)?

    var onGetAnalyticsError: ((String) -> Void)?
    var onGetAnalyticsSuccess: ((AnalyticsResponse) -> Void)?
    
    private let mpinService = MPINService()
    private let analyticsService = AnalyticsService()
    
    
//Me: coinStats, chorePercentages, goalPercentages, choreCounts, goalCounts will remain the same no matter what the period, page and limit is
//Preeti: Changing those query params only affects periodChores currently.
//    but you are correct the above mentioned field should change if period is given in query parameter
//    didn't raised by the testing team.
//    will look into it rachana!!
    
    func getAnalyticsInfo(childId: String) async {
        
        let period: Period = .all
           
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       do {
           let response = try await analyticsService.getAnalyticsInfoOfAChild(childID: childId, period: period)
           
           guard response.data?.success ?? false, let analyticsResp = response.data  else {

               let errorMessage: String
               
               if let apiError = response.error {
                   switch apiError {
                   case .apiError(let errorResponse):
                       errorMessage = errorResponse.message ?? "Unable to retrieve"
                       
                   case .requestFailed(let error):
                       errorMessage = error.localizedDescription
                       
                   default:
                       errorMessage = "Something went wrong"
                   }
               } else {
                   errorMessage = "Unable to retrieve"
               }
           
               DispatchQueue.main.async { [weak self] in
                   self?.onLoadingChanged?(false)
                   self?.onGetAnalyticsError?(errorMessage)
               }
               return
           }
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGetAnalyticsSuccess?(analyticsResp)
           }
       } catch {
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGetAnalyticsError?(error.localizedDescription)
           }
       }
   }

    func checkMPINStatus() async {
           
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       do {
           let response = try await mpinService.getMPINStatus()
           
           guard response.data?.success ?? false, let mpinDetails = response.data  else {

               let errorMessage: String
               
               if let apiError = response.error {
                   switch apiError {
                   case .apiError(let errorResponse):
                       errorMessage = errorResponse.message ?? "Unable to retrieve"
                       
                   case .requestFailed(let error):
                       errorMessage = error.localizedDescription
                       
                   default:
                       errorMessage = "Something went wrong"
                   }
               } else {
                   errorMessage = "Unable to retrieve"
               }
           
               DispatchQueue.main.async { [weak self] in
                   self?.onLoadingChanged?(false)
                   self?.onCheckMPINStatusError?(errorMessage)
               }
               return
           }
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onCheckMPINStatusSuccess?(mpinDetails)
           }
       } catch {
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onCheckMPINStatusError?(error.localizedDescription)
           }
       }
   }
}

enum AnalyticsSection: Int, CaseIterable {
    case chores = 0
    case goals = 1
    case milestones = 2
 
    var headerTitle: String {
        switch self {
        case .chores: return "Todays Chores Overview"
        case .goals: return "Goals Overview"
        case .milestones: return "Milestones achieved"
        }
    }
}
