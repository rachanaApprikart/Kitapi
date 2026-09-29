//
//  ChoreTemplate.swift
//  Kitapi
//
//  Created by Suneel on 23/06/26.
//

import Foundation
import UIKit

// MARK: - ChoreTemplateResponse

struct ChoreTemplateResponse: Codable {
    let success: Bool
    let message: String
    let data: [TemplateData]
    let pagination: Pagination
    let filters: FiltersChore?
}


struct TemplateData: Codable {
    
    let id, title: String
    let image: ProfilePicture?
    let video: ProfilePicture?
    let userID: String?
    let adminID, createdAt, updatedAt: String?
    let parent: LoggedInParent?
    let admin: Admin?
    let createdBy, creatorName: String?
    let usageStats: UsageStats?
    let creator: Creator?

    enum CodingKeys: String, CodingKey {
        case id, title, image, video
        case userID = "userId"
        case adminID = "adminId"
        case createdAt, updatedAt
        case parent = "parent"
        case admin = "Admin"
        case createdBy, creatorName, usageStats, creator
    }
}

struct Creator: Codable {
    let id: String
    let email: String
    let type: String
}

// MARK: - Admin
struct Admin: Codable {
    let id, email: String
}


// MARK: - UsageStats
struct UsageStats: Codable {
    let totalUsage, usagePercentage, completedTasks, completionRate: Int
    let totalRewardCoins, pendingTasks, upcomingTasks, overdueTasks: Int
    let justCompletedTasks: Int
}

// MARK: - Filters

struct FiltersChore: Codable {
    let search, createdBy: String?
    let sortBy, sortOrder: String?
    let userID, adminID: String?

    enum CodingKeys: String, CodingKey {
        case search, createdBy, sortBy, sortOrder
        case userID = "userId"
        case adminID = "adminId"
    }
}

//MARK: Create template

struct CreateChoreTemplateRequest {
    let title: String
    let image: UIImage
}

// MARK: - ChoreTemplateResponse

struct CreateChoreTemplateResponse: Codable {
    let success: Bool
    let message: String
    let data: TemplateData
}

