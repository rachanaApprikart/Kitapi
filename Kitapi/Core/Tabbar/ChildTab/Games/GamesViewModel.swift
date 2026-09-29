//
//  GamesViewModel.swift
//  Kitapi
//
//  Created by Suneel on 05/09/26.
//

import Foundation

class GamesViewModel {
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onGetGamesError: ((String) -> Void)?
    var onGetGamesSuccess: ((GamesResponse) -> Void)?
    
    var onStartGameError: ((String) -> Void)?
    var onStartGameSuccess: ((StartGameResponse) -> Void)?
   
    private let gameService = GameService()

    func getAllGames(childId: String) async {
        
       DispatchQueue.main.async { [weak self] in
           self?.onLoadingChanged?(true)
       }
       do {
           let response = try await gameService.getGames(childId: childId)
           
           guard response.data?.success ?? false, let gameResp = response.data  else {

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
                   self?.onGetGamesError?(errorMessage)
               }
               return
           }
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGetGamesSuccess?(gameResp)
           }
       } catch {
           DispatchQueue.main.async { [weak self] in
               self?.onLoadingChanged?(false)
               self?.onGetGamesError?(error.localizedDescription)
           }
       }
   }

    func startGame(gameId: String, childId: String) async {
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            
            let response = try await gameService.startGameRequest(childId: childId, gameId: gameId)
            
            // Validate response
            guard response.data?.success ?? false, let startGameResponse = response.data else {
                
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                        
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to create MPIN"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Failed to create MPIN"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onStartGameError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onStartGameSuccess?(startGameResponse)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onStartGameError?(error.localizedDescription)
            }
        }
    }
}


