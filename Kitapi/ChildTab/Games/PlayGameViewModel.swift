//
//  PlayGameViewModel.swift
//  Kitapi
//
//  Created by Suneel on 07/09/26.
//

import Foundation


class PlayGameViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onEndGamesError: ((String) -> Void)?
    var onEndGamesSuccess: ((EndGameResponse) -> Void)?
    
    private let gameService = GameService()
    
    func engGameRequest(requestId: String, tokenScope: TokenScope) async {
          
          DispatchQueue.main.async { [weak self] in
              self?.onLoadingChanged?(true)
          }
          do {
              let response = try await gameService.endGame(gameRequestId: requestId, tokenScope: tokenScope)
              
              guard response.data?.success ?? false, let endGameResp = response.data else {
                  let errorMessage: String
                  if let apiError = response.error {
                      switch apiError {
                      case .apiError(let errorResponse):
                          errorMessage = errorResponse.message ?? "Unable to retrieve"
                      case .requestFailed(let error):
                          errorMessage = error.localizedDescription
                      default:
                          errorMessage = "Something went wrong"
                      }
                  } else {
                      errorMessage = "Unable to retrieve"
                  }
                  
                  DispatchQueue.main.async { [weak self] in
                      self?.onLoadingChanged?(false)
                      self?.onEndGamesError?(errorMessage)
                  }
                  return
              }
              DispatchQueue.main.async { [weak self] in
                  self?.onLoadingChanged?(false)
                  self?.onEndGamesSuccess?(endGameResp)
              }
          } catch {
              DispatchQueue.main.async { [weak self] in
                  self?.onLoadingChanged?(false)
                  self?.onEndGamesError?(error.localizedDescription)
              }
          }
      }
}


