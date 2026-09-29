//
//  ChoreDetails.swift
//  Kitapi
//
//  Created by Suneel on 02/09/26.
//

import Foundation


struct TaskDetailsResponse: Codable {
    let success: Bool
    let message: String
    let data: TaskDetailsData
}

struct TaskDetailsData: Codable {
    let task: TaskData?
    let taskTemplate: TemplateData?
    let child: Child?
    let accessLevel: String?
    let canModify: Bool?
    let canComplete: Bool?
    let canApproveReject: Bool?
}

struct TaskDetail: Codable {
    let id: String
    let dueDate: String
    let startTime: String
    let endTime: String
    let audioDescription: String?
    let description: String
    let status: String
    let rewardCoins: Int
    let recurrence: String
    let isRecurring: Bool
    let batchId: String?
    let createdAt: String
    let updatedAt: String
    let completedAt: String?
    let dueDateFormatted: String
    let completedAtFormatted: String?
}

//struct TaskTemplate: Codable {
//    let id: String
//    let title: String
//    let image: TaskImage?
//    let video: TaskVideo?
//    let createdAt: String
//    let updatedAt: String
//    let createdBy: String
//    let creator: Creator
//}
//
//struct TaskImage: Codable {
//    let url: String
//    let filename: String
//    let originalName: String
//    let size: Int
//    let mimetype: String
//}
//
//struct TaskVideo: Codable {
//    let url: String
//    let filename: String
//    let originalName: String
//    let size: Int
//    let mimetype: String
//}
//

//
//struct TaskChild: Codable {
//    let id: String
//    let name: String
//    let age: Int
//    let parentId: String
//    let parent: TaskParent
//}
//
//struct TaskParent: Codable {
//    let id: String
//    let name: String
//    let email: String
//}
