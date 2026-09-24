//
//  Chore.swift
//  Kitapi
//
//  Created by Suneel on 18/07/26.
//

import Foundation

struct CreateChoreRequest: Codable {
    let taskTemplateId: String
    let childId: String
    let description: String
    let startTime, endTime: String
    let recurrence: String
    let recurrenceDates: [String]
}

struct CreateChoreResponse: Codable {
    let success: Bool
    let message: String
    let data: ChoreData
}


struct ChoreData: Codable {
    let taskTemplateID, title: String
    let image: ProfilePicture
    let video: ProfilePicture?
    let tasks: [TaskData]
    let userId, adminId: String?

    enum CodingKeys: String, CodingKey {
        case taskTemplateID = "taskTemplateId"
        case title, image, tasks, video, userId, adminId
    }
}



// MARK: - Task

struct TaskData: Codable {
    let id: String
    let dueDate: String?
    let startTime, endTime: String?
    let recurrence: Recurrence?
    let status: ChoreStatus?
    let description: String?
    let batchID: String?
    let title: String?
    let image: ProfilePicture?
    let video: ProfilePicture?
    let audioDescription: AudioDescription?
    let taskTemplateId, parentId, childId: String?
    let rewardCoins: Int?
    let isRecurring: Bool?
    let completedAt, rejectedAt: String?
    let rejectionReason: String?
    let isGoalTask: Bool?
    let template: TemplateData?
    let taskTemplate: TemplateData?
    let createdAt: String?
    let updatedAt: String?
    let dueDateFormatted: String?
    let completedAtFormatted: String?
   
    
    enum CodingKeys: String, CodingKey {
        case id, dueDate, startTime, endTime, description, audioDescription, taskTemplateId
        case batchID = "batchId"
        case childId, parentId, recurrence, status, rewardCoins, isRecurring
        case completedAt, rejectedAt, rejectionReason, image, video, title, isGoalTask, template
        case taskTemplate = "TaskTemplate"
        case updatedAt, createdAt, completedAtFormatted, dueDateFormatted
    }
}

struct AudioDescription: Codable {
    let url: String
    let filename: String
    let originalName: String
    let size: Int
    let mimetype: String
}

struct GetAllChoresRequest: Codable {
    let page: String
    let limit: String
    let status: ChoreStatus
    let childId: String
    let sortOrder: String
}

struct GetAllChoresResponse: Codable {
    let success: Bool
    let message: String
    let data: DataClass
}

// MARK: - DataClass
struct DataClass: Codable {
    let tasks: [TaskData]
    let pagination: PageData
    let appliedFilters: AppliedFilters
}

// MARK: - AppliedFilters

struct AppliedFilters: Codable {
    let status: ChoreStatus
    let dueDateFrom, dueDateTo: String?
    let childID, sortBy, sortOrder: String?
    let search: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case status, dueDateFrom, dueDateTo
        case childID = "childId"
        case sortBy, sortOrder, search, type
    }
}

// MARK: - Pagination

struct PageData: Codable {
    let total, limit, totalPages: Int
    let offset: Int?
    let page: Int?
}

enum Recurrence: String, Codable {
    case once
    case daily
    case weekly
    case monthly
    
    var repeatType: RepeatType {
        switch self {
        case .once: return .once
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }
}

enum ChoreStatus: String, Codable {
    case upcoming
    case pending
    case completed
    case rejected
    case overdue
    case all
}


struct ChoreStatusUpdateRequest {
    let taskId: String
    let childId: String
    let status: ChoreStatus?
    let reason: String?
}

struct ChoreStatusUpdateResponse: Codable {
    let success: Bool
    let message: String
    let data: UpdateData?
}

struct UpdateData: Codable {
    let task: TaskData
    let child: Child
}




