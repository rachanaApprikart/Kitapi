//
//  ChoreViewModel.swift
//  Kitapi
//
//  Created by Suneel on 22/07/26.
//

import Foundation

class ChoreViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onErrorToGetAllChores: ((String) -> Void)?
    var onGetAllChoresSuccess: ((GetAllChoresResponse) -> Void)?
    var onSectionsUpdated: (([ChoreSection]) -> Void)?
    
    private let choreService = ChoreService()
    
    func fetchAllChores(childId: String) async {
        
        let requestBody = GetAllChoresRequest(page: "1", limit: "100", status: .all, childId: childId, sortOrder: "DESC")
        
        // Show loading
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            // Make async API call
            let response = try await choreService.getAllChores(request: requestBody)
            
            // Validate response
            guard response.data?.success ?? false, let childDetails = response.data  else {
                // API Error
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
                    self?.onErrorToGetAllChores?(errorMessage)
                }
                return
            }
           
            // Build sections from the tasks inside it
            let tasks = childDetails.data.tasks
            let sections = self.buildSections(from: tasks)
            
            // Success
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onGetAllChoresSuccess?(childDetails)
                self?.onSectionsUpdated?(sections)
            }
            
        } catch {
            // Network/Unknown Error
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onErrorToGetAllChores?(error.localizedDescription)
            }
        }
    }
    
    // Buckets the flat API response into the 3 sections shown in the UI.
    
    func buildSections(from chores: [TaskData]) -> [ChoreSection] {
        
        let upNext = chores
            .filter { $0.status == .upcoming }
            .sorted { $0.dueDate ?? "" < $1.dueDate ?? "" } // soonest first
        
        let completed = chores
            .filter { $0.status == .completed }
            .sorted { $0.dueDate ?? "" > $1.dueDate ?? "" } // most recently completed first
        
        // Everything else lands in the middle "All Chores" section:
        // pending, rejected, overdue
        let remaining = chores
            .filter { [.pending, .rejected, .overdue].contains($0.status) }
          //  .sorted { $0.dueDate ?? "" < $1.dueDate ?? "" }
        
        return [
            ChoreSection(type: .upNext, chores: upNext),
            ChoreSection(type: .all, chores: remaining),
            ChoreSection(type: .completed, chores: completed)
        ].filter { !$0.chores.isEmpty }
    }
}


struct ChoreSection {
    let type: ChoreSectionType
    let chores: [TaskData]
}
enum ChoreSectionType {
    case upNext
    case all
    case completed
    
    var title: String {
        switch self {
        case .upNext:
            return "Up Next"
        case .all:
            return "All Chores"
        case .completed:
            return "Completed chores"
        }
    }
    
    var isHorizontal: Bool {
        switch self {
        case .upNext:
            return true
        case .all, .completed:
            return false
        }
    }
}
