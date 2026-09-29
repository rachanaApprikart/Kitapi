//
//  Password.swift
//  Kitapi
//
//  Created by Suneel on 23/04/26.
//

import Foundation

struct ForgotPasswordResponse: Codable {
    let success: Bool
    let message: String
    let userId: String
}

struct ResetPasswordRequest: Codable {
    let email: String
    let otp: String
    let password: String
}

struct ResetPasswordResponse: Codable {
    let success: Bool
    let message: String
}

