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
    let parentId: String?
}

// MARK: - ProfilePicture
struct ProfilePicture: Codable {
    let url: String?
    let filename, originalName: String?
    let size: Int?
    let mimetype: String?
}

enum Mimetype: String, Codable {
    // MARK: - Image
    case imageJPEG = "image/jpeg"
    case imageJPG = "image/jpg"
    case imagePNG = "image/png"
    case imageWebP = "image/webp"
    case imageSVG = "image/svg+xml"

    // MARK: - Video
    case videoMP4 = "video/mp4"
    case videoMPEG = "video/mpeg"
    case videoQuickTime = "video/quicktime"
    case videoXMSVideo = "video/x-msvideo"
    case videoWebM = "video/webm"

    // MARK: - Audio
    case audioMPEG = "audio/mpeg"
    case audioMP3 = "audio/mp3"
    case audioWAV = "audio/wav"
    case audioWAVE = "audio/wave"
    case audioXWAV = "audio/x-wav"
    case audioAAC = "audio/aac"
    case audioM4A = "audio/m4a"
    case audioXM4A = "audio/x-m4a"
    case audioOGG = "audio/ogg"
    case audioWebM = "audio/webm"
    case audioFLAC = "audio/flac"
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

struct DeleteChildProfileResponse: Codable {
    let message: String
}
