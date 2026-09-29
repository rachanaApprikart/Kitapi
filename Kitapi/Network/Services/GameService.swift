//
//  GameService.swift
//  Kitapi
//
//  Created by Suneel on 05/09/26.
//

import Foundation

struct GameService {
    
    func getGames(childId: String) async throws -> APIResponse<GamesResponse> {
        
        var url = GameEndPoint.getAllGames.getFullPath()
        
        let parameters: [String: String] = ["childId": childId]
        
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let urlwithQueryItems = url.queryString(params: parameters) else {
            return await APIClient.callAPIWithRawData(url: url, method: .get, tokenScope: .parent)
        }
        url = urlwithQueryItems
        return await APIClient.callAPIWithRawData(url: url, method: .get, tokenScope: .parent)
    }
    
    func startGameRequest(childId: String, gameId: String) async throws -> APIResponse<StartGameResponse> {
        
        let url = GameEndPoint.startGame.getFullPath()
        
        let requestBody: [String: String] = ["gameId": gameId,
                                             "childId": childId]
        
        guard let data = requestBody.toData() else {
            return await APIClient.callAPIWithRawData(url: url, method: .post, tokenScope: .parent)
        }
        return await APIClient.callAPIWithRawData(url: url, method: .post, body: data, tokenScope: .parent)
    }
    
    func endGame(gameRequestId: String, tokenScope: TokenScope) async throws -> APIResponse<EndGameResponse> {
        let url = GameEndPoint.endGame(id: gameRequestId).getFullPath()
        return await APIClient.callAPIWithRawData(url: url, method: .put, tokenScope: tokenScope)
    }
}

enum GameEndPoint {
    
    case getAllGames
    case startGame
    case endGame(id: String)
    
    private func getURLPath() -> String {
        switch self {
            
        case .getAllGames:
            return "/api/game/child/games"
            
        case .startGame:
            return "/api/game/start-game"
            
        case .endGame(let id):
            return "/api/game/end-game/\(id)"
       }
    }
    
    func getFullPath() -> String {
        return BASE_URL + self.getURLPath()
    }
}
