//
//  Registration.swift
//  Kitapi
//
//  Created by Suneel on 13/04/26.
//

import Foundation


struct RegistrationResponse: Codable {
    let success: Bool?
    let message: String?
    let user: User?
}

// MARK: - User
struct User: Codable {
    let id: String
    let notificationEnabled: Bool
    let email, name: String
    let gender, phone, countryCode: String?
    let preferredLanguage, lastActiveAt: String?
    let image, mpin, lastLoginAt, deviceType: String?
    let fcmToken, deviceVersion: String?
}

// Request Model
struct RegisterRequest: Codable {
    let name: String
    let countryCode: String
    let phone: String?
    let gender: String
    let email: String
    let password: String
}
