//
//  AllChoresViewModel.swift
//  Kitapi
//
//  Created by Suneel on 16/11/26.
//

import Foundation

class AllChoreViewModel {
    
    
    // MARK: - Callbacks
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onLoadingMoreChanged: ((Bool) -> Void)?
    var onErrorToGetAllChores: ((String) -> Void)?
    var onGetAllChoresSuccess: ((GetAllChoresResponse) -> Void)?
    var onChoresUpdated: (([TaskData]) -> Void)?
    
    // MARK: - Properties
    
    private let choreService = ChoreService()
    
    private(set) var chores: [TaskData] = []
    
    private(set) var currentPage: Int = 1
    private(set) var totalPages: Int = 1
    
    private let pageLimit: Int = 10
    
    private var isLoading = false
    private var isLoadingMore = false
    
    private var currentChildId: String?
    
    private var hasMorePages: Bool {
        currentPage < totalPages
    }
    
    // MARK: - Filters
    
    var selectedStatus: ChoreStatus = .all
    
    // MARK: - Fetch All Chores
    
    func fetchAllChores(childId: String) async {
        
        guard !isLoading, !isLoadingMore else { return }
        
        // Reset pagination for initial request
        currentChildId = childId
        currentPage = 1
        totalPages = 1
        chores.removeAll()
        
        await fetchChores(childId: childId, page: 1, isFirstPage: true)
    }
    
    // MARK: - Load More Chores
    
    func loadMoreChores(childId: String) async {
        
        guard !isLoading,
              !isLoadingMore,
              hasMorePages,
              currentChildId == childId else {
            return
        }
        
        let nextPage = currentPage + 1
        
        await fetchChores(
            childId: childId,
            page: nextPage,
            isFirstPage: false
        )
    }
    
    // MARK: - API Call
    
    private func fetchChores(
        childId: String,
        page: Int,
        isFirstPage: Bool
    ) async {
        
        if isFirstPage {
            isLoading = true
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(true)
            }
            
        } else {
            isLoadingMore = true
            
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingMoreChanged?(true)
            }
        }
        
        let requestBody = GetAllChoresRequest(
            page: "\(page)",
            limit: "\(pageLimit)",
            status: selectedStatus,
            childId: childId,
            sortOrder: "ASC"
        )
        
        do {
            
            // API Call
            let response = try await choreService.getAllChores(
                request: requestBody
            )
            
            // Validate Response
            guard response.data?.success ?? false,
                  let choreDetails = response.data else {
                
                let errorMessage: String
                
                if let apiError = response.error {
                    
                    switch apiError {
                        
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Unable to retrieve chores"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(_):
                        
                        if isFirstPage {
                            isLoading = false
                        } else {
                            isLoadingMore = false
                        }
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.onLoadingChanged?(false)
                            self?.onLoadingMoreChanged?(false)
                        }
                        
                        return
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                    
                } else {
                    errorMessage = "Unable to retrieve chores"
                }
                
                if isFirstPage {
                    isLoading = false
                } else {
                    isLoadingMore = false
                }
                
                DispatchQueue.main.async { [weak self] in
                    
                    self?.onLoadingChanged?(false)
                    self?.onLoadingMoreChanged?(false)
                    self?.onErrorToGetAllChores?(errorMessage)
                }
                
                return
            }
            
            // Get Tasks and Pagination
            let newTasks = choreDetails.data.tasks
            let pagination = choreDetails.data.pagination
            
            // Store Tasks
            if isFirstPage {
                chores = newTasks
            } else {
                chores.append(contentsOf: newTasks)
            }
            
            // Update Pagination
            currentPage = page
            totalPages = pagination.totalPages
            
            // Reset Loading
            isLoading = false
            isLoadingMore = false
            
            // Success
            DispatchQueue.main.async { [weak self] in
                
                self?.onLoadingChanged?(false)
                self?.onLoadingMoreChanged?(false)
                
                self?.onGetAllChoresSuccess?(choreDetails)
                self?.onChoresUpdated?(self?.chores ?? [])
            }
            
        } catch {
            
            // Network / Unknown Error
            if isFirstPage {
                isLoading = false
            } else {
                isLoadingMore = false
            }
            
            DispatchQueue.main.async { [weak self] in
                
                self?.onLoadingChanged?(false)
                self?.onLoadingMoreChanged?(false)
                
                self?.onErrorToGetAllChores?(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Change Status
    
    func changeStatus(_ status: ChoreStatus, childId: String) async {
        
        guard selectedStatus != status else { return }
        
        selectedStatus = status
        
        await fetchAllChores(childId: childId)
    }
    
    // MARK: - Reset Pagination
    
    func resetPagination() {
        
        currentPage = 1
        totalPages = 1
        chores.removeAll()
    }
}


