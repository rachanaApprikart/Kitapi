//
//  Games.swift
//  Kitapi
//
//  Created by Suneel on 05/09/26.
//

import Foundation

struct GamesResponse: Codable {
    let success: Bool
    let data: GamesData
}

struct GamesData: Codable {
    let games: [Game]
    let childDetails: Child?
    let activeRequestsCount: Int?
    let userType: String?
}

struct Game: Codable {
    let id: String
    let name: String
    let description: String?
    let rulesRegulations: [String]
    let htmlUrl: GameMedia?
    let image: [GameMedia]
    let video: [GameMedia]
    let ageLimitMin: Int?
    let ageLimitMax: Int?
    let allotedCoin: Int?
    let requestStatus: RequestStatus?
    let canRequest: Bool?
    let insufficientCoins: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case rulesRegulations = "rules_regulations"
        case htmlUrl = "html_url"
        case image
        case video
        case ageLimitMin = "age_limit_min"
        case ageLimitMax = "age_limit_max"
        case allotedCoin = "alloted_coin"
        case requestStatus
        case canRequest
        case insufficientCoins
    }
}

struct GameMedia: Codable {
    let url: String
    let filename: String
    let originalName: String
    let size: Int
    let mimetype: String
    let cdnEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case url
        case filename
        case originalName
        case size
        case mimetype
        case cdnEnabled
    }
}

struct RequestStatus: Codable {
    let hasActiveRequest: Bool
    let status: String
}

//MARK: START GAME

struct StartGameResponse: Codable {
    let success: Bool
    let message: String
    let data: StartGameData
}

struct StartGameData: Codable {
    let gameRequest: GameRequest?
    let gameSession: GameSession?
    let child: Child?
    let transaction: GameTransaction?
}

struct GameRequest: Codable {
    let id: String
    let status: String?
    let gameId: String?
    let gameName: String?
    let childId: String?
    let childName: String?
    let coinsSpent: Int?
}

struct GameSession: Codable {
    let id: String
    let status: String?
    let startedAt: String?
}

struct GameTransaction: Codable {
    let id: String
    let type: String?
    let amount: Int?
}

//MARK: END GAME

struct EndGameResponse: Codable {
    let success: Bool
    let message: String
    let data: EndGameData
}

struct EndGameData: Codable {
    let gameSessionId: String?
    let status: String?
    let duration: Int?
    let coinsSpent: Int?
    let endedAt: String?
}
