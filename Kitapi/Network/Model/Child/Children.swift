//
//  Children.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import Foundation


struct ChildrenDetailsRequest: Codable {
    let page: String
    let limit: String
//    let minAge: String
//    let maxAge: String
    let sortOrder: String
}

//MARK: --------- RESPONSE -----------

struct ChildrenDetails: Codable {
    let success: Bool
    let children: [Child]
    let pagination: Pagination
    let filters: Filters
    let summary: Summary
}

// MARK: Child
struct Child: Codable {
    let id, name: String
    let dateOfBirth: String?
    let age: Int?
    let gender: String?
    let profilePicture: ProfilePicture?
    let coinBalance, totalEarned: Int?
    let parent: Parent?
    let goalsStats, tasksStats: Stats?
    let balanceBefore: Int?
    let coinsSpent: Int?
}

// MARK: - ProfilePicture
struct ProfilePicture: Codable {
    let url: String?
    let filename, originalName: String?
    let size: Int?
    let mimetype: Mimetype?
}

enum Mimetype: String, Codable {
    case imageJPEG = "image/jpeg"
    case imagePNG = "image/png"
    case videoMp4 = "video/mp4"
}


// MARK: Stats
struct Stats: Codable {
    let completed, total, completionPercentage: Int
    let displayText: String
}

// MARK: Parent
struct Parent: Codable {
    let id, name: String
    let email: String?
}

// MARK: Filters
struct Filters: Codable {
    let sortBy, sortOrder: String
}

struct Pagination: Codable {
    let currentPage, totalPages, totalItems, itemsPerPage: Int
    let hasNextPage, hasPrevPage: Bool
    let nextPage, prevPage: String?
    let startIndex, endIndex: Int?
}

// MARK: Summary
struct Summary: Codable {
    let totalChildrenInDatabase, childrenOnCurrentPage, averageGoalCompletion, averageTaskCompletion: Int
}
