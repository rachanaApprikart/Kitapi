//
//  GoalDetails.swift
//  Kitapi
//
//  Created by Suneel on 31/08/26.
//

import Foundation

struct GetGoalDetailsResponse: Codable {
    let success: Bool
    let message: String
    let data: GoalDetails
}

struct GoalDetails: Codable {
    let id: String
    let title: String
    let description: String?
    let image: ProfilePicture?
    let goalType: GoalType
    let milestoneAmount: Int?
    let status: ChoreStatus
    let child: Child
    let parentId: String
    let tasks: [TaskData]
    let progress: GoalProgressDetails
    let completedAt: String?
    let createdAt: String?
}


//struct GoalTask: Codable {
//    let id: String
//    let dueDate: String
//    let status: String
//    let description: String?
//    let taskTemplate: TaskTemplate
//
//    enum CodingKeys: String, CodingKey {
//        case id
//        case dueDate
//        case status
//        case description
//        case taskTemplate = "TaskTemplate"
//    }
//}

//struct TaskTemplate: Codable {
//    let id: String
//    let title: String
//    let image: TaskImage?
//}

//struct TaskImage: Codable {
//    let url: String
//    let filename: String
//    let originalName: String
//    let size: Int
//    let mimetype: String
//}


