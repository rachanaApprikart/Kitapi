//
//  AvailableChores.swift
//  Kitapi
//
//  Created by Suneel on 30/08/26.
//

import Foundation


struct AvailableChoresResponse: Decodable {
    let success: Bool
    let message: String
    let data: AvailableChoresData
}

struct AvailableChoresData: Decodable {
    let child: Child
    let availableChores: [TaskData]
    let totalAvailable: Int
}
