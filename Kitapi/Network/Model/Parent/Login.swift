//
//  Login.swift
//  Kitapi
//
//  Created by Suneel on 23/04/26.
//

import Foundation


//MARK: Login

struct LoginRequest: Codable {
    let email: String
    let password: String
    let fcmToken: String
    let deviceType: String
    let deviceVersion: String?
}

// MARK: - LoginResponse

struct LoginResponse: Codable {
    let success: Bool
    let message, token: String
    let user: VerifiedParent?
}

// MARK: - LoggedInParent

struct ParentDetails: Codable {
    let success: Bool
    let message: String
    let user: LoggedInParent?
}

struct LoggedInParent: Codable {
    let id, name, email: String
    let image: Date?
    let gender: String
    let countryCode, phone: String?
    let isActive, isEmailVerified, biometricEnabled: Bool?
    let biometricSetupAt, biometricPublicKey, biometricLastUsedAt: String?
    let lastActiveAt: String?
    let notificationEnabled: Bool?
    let preferredLanguage, createdAt, updatedAt: String?
}

//Mark: Google login

struct GoogleLoginRequest: Codable {
    let fcmToken: String
    let deviceType: String
    let deviceVersion: String?
}
