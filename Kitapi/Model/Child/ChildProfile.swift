//
//  ChildProfile.swift
//  Kitapi
//
//  Created by Suneel on 15/05/26.
//

import Foundation
import UIKit

enum AvatarSectionType {
    case pickerOptions
    case boys
    case girls
}

struct AvatarSection {
    let type: AvatarSectionType
    let title: String?
    let items: [UIImage]
}

// Request Model
struct ChildProfileRequest {
    let name: String
    let dateOfBirth: String
    let gender: String
    let profilePicture: UIImage?
}

// MARK: -
struct ChildProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: Child
}


