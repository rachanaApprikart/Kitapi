//
//  ErrorModel.swift
//  Kitapi
//
//  Created by Suneel on 13/04/26.
//

import Foundation


// Error Model

struct APIError: Codable {
    let success: Bool?
    let message: String?
}

// MARK: - NETWORK Layer

enum NetworkError: Error {
    case invalidURL
    case authenticationFailed(APIError)
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed
    case apiError(APIError)
    case unknown
}
