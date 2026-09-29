//
//  Verification.swift
//  Kitapi
//
//  Created by Suneel on 20/04/26.
//

import Foundation

//MARK: send otp

struct SendOTPRequest: Codable {
    let email: String
}

struct SendOTPResponse: Codable {
    let success: Bool
    let message, email: String
}

//MARK: verify otp

struct VerifyOTPRequest: Codable {
    let email: String
    let otp: String
    let fcmToken: String
    let deviceType: String
    let deviceVersion: String?
}

struct VerificationResponse: Codable {
    let success: Bool
    let message, token: String
    let data: VerifiedParent?
}

struct VerifiedParent: Codable {
    let id, name, email: String
    let deviceType, deviceVersion: String?
    let image: Data?
    let gender: String?
    let fcmToken, preferredLanguage: String?
    let isEmailVerified: Bool?
}



