//
//  CreateGoal.swift
//  Kitapi
//
//  Created by Suneel on 25/08/26.
//

import Foundation

struct CreateGoalRequest: Codable {
    let title: String
    let description: String
    let childId: String
    let goalType: String
    let taskIds: [String]?
    let milestoneAmount: Int?
}

enum GoalType: String, Codable {
    case gift
    case milestone
    case all
}

struct GoalResponse: Codable {
    let success: Bool
    let message: String
    let data: GoalData
}

struct GoalData: Codable {
    let id: String
    let title: String
    let description: String?
    let image: ProfilePicture?
    let type: String?
    let goalType: GoalType
    let milestoneAmount: Int?
    let status: ChoreStatus
    let completedAt: String?
    let rejectedAt: String?
    let rejectionReason: String?
    let createdAt: String?
    let updatedAt: String?
    let childId: String?
    let parentId: String?
    let child: Child?
    let parent: Parent?
    let tasks: [TaskData]?
  //  let tasksCount: Int?
    let completedTaskCount: Int?
    let progressPercentage: Double?
    let progressDetails: GoalProgressDetails?
    let currentCoins: Int?
    let taskCount: Int?
}

struct GetAllGoalsRequest: Codable {
    let page: String
    let limit: String
    let type: GoalType
    let status: ChoreStatus
    let sortOrder: String
}

struct GetAllGoalResponse: Codable {
    let success: Bool
    let message: String
    let data: GetAllGoals
}

struct GetAllGoals: Codable {
    let child: Child
    let goals: [GoalData]
    let pagination: PageData
    let filters: AppliedFilters
}
