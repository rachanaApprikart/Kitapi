//
//  MPIN.swift
//  Kitapi
//
//  Created by Suneel on 04/08/26.
//

import Foundation

struct CheckMPINStatus: Codable {
    let success: Bool
    let data: MPINData
}

// MARK: - MPINData

struct MPINData: Codable {
    let isSetup: Bool
    let isLocked, lockRemainingMinutes: String?
    let failedAttempts, maxAttempts: Int
    let setupDate: String?
}

struct MPINResponse: Codable {
    let success: Bool
    let message: String
}


struct EnableChildModeRequest: Codable {
    let childId: String
    let mpin: String
    let sessionDuration: String
}

struct EnableChildModeResponse: Codable {
    let success: Bool
    let message: String
    let data: EnableChildModeData
}

struct EnableChildModeData: Codable {
    let token, childID, childName, parentID: String?
    let sessionDuration, expiresAt, startTime: String?

    enum CodingKeys: String, CodingKey {
        case token
        case childID = "childId"
        case childName
        case parentID = "parentId"
        case sessionDuration, expiresAt, startTime
    }
}

struct DisableChildModeRequest: Codable {
    let isManual: Bool
    let mpin: String
    let authMethod: String
}

enum AuthenticationMethod: String, Codable {
    case biometric
    case mpin
}

struct DisableChildModeResponse: Codable {
    let success: Bool
    let message: String
    let data: DisableChildMode
}

struct DisableChildMode: Codable {
    let sessionEnded: Bool
    let isExpired: Bool
    let previousChildId: String
    let previousSessionDuration: String
    let endedAt: String
    let requiresReauth: Bool
}
