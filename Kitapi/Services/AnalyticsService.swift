//
//  AnalyticsService.swift
//  Kitapi
//
//  Created by Suneel on 10/08/26.
//

import Foundation


struct AnalyticsService {
    
    // Only periodChores will vary based on page, limit and status and status.But UI doesn't require periodChores, hence limit is 1. By default its 15
    
    //By default "period": "day", "status": "all"
    
    func getAnalyticsInfoOfAChild(childID: String, period: Period) async throws -> APIResponse<AnalyticsResponse> {
          
          var url = AnalyticsEndPoint.getAnalytics(childID: childID).getFullPath()
          
          let requestBody: [String: String] = ["period": period.rawValue,
                                               "limit": "1"]
          
          guard let urlWithQueryItems = url.queryString(params: requestBody) else {
              return await APIClient.callAPIWithRawData(url: url, method: .get)
          }
          url = urlWithQueryItems
          return await APIClient.callAPIWithRawData(url: url, method: .get)
      }
}

enum AnalyticsEndPoint {
    
    case getAnalytics(childID: String)
    
    private func getURLPath() -> String {
        
        switch self {
        case .getAnalytics(let childID):
            return "/api/child/analytic/\(childID)"
        }
    }
    
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
