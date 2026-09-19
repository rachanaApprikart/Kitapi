//
//  UpdateGoal.swift
//  Kitapi
//
//  Created by Suneel on 02/09/26.
//

import Foundation

struct RequestAddGoalsForTask: Codable {
    let taskIds: [String]
}

struct GoalUpdateResponse: Codable {
    let success: Bool
    let message: String
    let data: GoalData
}

struct UpdateGoalStatusRequest: Codable {
    let goalId: String
    let childId: String
    let status: ChoreStatus?
    let rejectedReason: String?
}

struct UpdateGoalStatusResponse: Codable {
    let success: Bool
    let message: String
    let data: GoalStatusData
}

struct GoalStatusData: Codable {
    let goalId: String
    let title: String
    let goalType: String
    let childName: String
    let status: String
    let completedAt: String?
    let taskCount: Int
}
