//
//  Reauth.swift
//  Kitapi
//
//  Created by Suneel on 09/09/26.
//

import Foundation

struct ParentReauthRequest: Codable {
    let authMethod: String
    let mpin: String
}

struct ParentReauthResponse: Codable {
    let success: Bool
    let message: String
    let data: ParentReauthData?
}

struct ParentReauthData: Codable {
    let parentId: String
    let parentName: String?
    let email: String?
    let authMethod: String?
    let childModeExited: Bool?
    let message: String?
    let redirectTo: String?
}
