//
//  MPINViewModel.swift
//  Kitapi
//
//  Created by Suneel on 05/08/26.
// verify mpin 11/08

import Foundation

class MPINViewModel {
    
    var childID: String = ""
    var duration: String = ""

    var onLoadingChanged: ((Bool) -> Void)?
    var onCreateMPINError: ((String) -> Void)?
    var onCreateMPINSuccess: ((MPINResponse) -> Void)?
    
    var onEnableChildModeError: ((String) -> Void)?
    var onEnableChildModeSuccess: ((EnableChildModeResponse) -> Void)?
    
    var onDisableChildModeError: ((String) -> Void)?
    var onDisableChildModeSuccess: ((DisableChildModeResponse) -> Void)?
    
    private let mpinService = MPINService()
    
    
    func createMPIN(mpin: String) async {
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            
            let response = try await mpinService.createMpin(with: mpin)
            
            // Validate response
            guard response.data?.success ?? false, let mpinResponse = response.data else {
                
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                        
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to create MPIN"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to create MPIN"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Failed to create MPIN"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onCreateMPINError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateMPINSuccess?(mpinResponse)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onCreateMPINError?(error.localizedDescription)
            }
        }
    }
    
    func enableChildMode(mpin: String) async {
        
        let requestBody = EnableChildModeRequest(childId: self.childID,
                                                 mpin: mpin,
                                                 sessionDuration: self.duration)
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            
            let response = try await mpinService.enableChildMode(request: requestBody)
            
            guard response.data?.success ?? false, let childModeResponse = response.data else {
                
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                        
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to enable child mode"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    case .authenticationFailed(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to enable child mode"
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Failed to enable child mode"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onEnableChildModeError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onEnableChildModeSuccess?(childModeResponse)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onEnableChildModeError?(error.localizedDescription)
            }
        }
    }
    
    func disableChildModeWithMPIN(mpin: String) async {
        
        let requestBody = DisableChildModeRequest(isManual: true, mpin: mpin, authMethod: AuthenticationMethod.mpin.rawValue)
        
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingChanged?(true)
        }
        
        do {
            
            let response = try await mpinService.disableChildMode(request: requestBody)
            
            guard response.data?.success ?? false, let childModeResponse = response.data else {
                
                let errorMessage: String
                
                if let apiError = response.error {
                    switch apiError {
                        
                    case .apiError(let errorResponse):
                        errorMessage = errorResponse.message ?? "Failed to disable with MPIN"
                        
                    case .requestFailed(let error):
                        errorMessage = error.localizedDescription
                        
                    default:
                        errorMessage = "Something went wrong"
                    }
                } else {
                    errorMessage = response.data?.message ?? "Failed to disable witn MPIN"
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onLoadingChanged?(false)
                    self?.onDisableChildModeError?(errorMessage)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onDisableChildModeSuccess?(childModeResponse)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingChanged?(false)
                self?.onDisableChildModeError?(error.localizedDescription)
            }
        }
    }
}

enum MPINMode {
    case create
    case enable
    case disable
    
    var title: String {
        switch self {
        case .create: return "Create MPIN to switch"
        case .enable: return "Enter MPIN to switch"
        case .disable: return "Enter MPIN to switch"

        }
    }
    
    var subtitle: String {
        switch self {
        case .create: return "To switch to child mode create your MPIN"
        case .enable: return "To switch to child mode enter your MPIN"
        case .disable: return "To switch to parent mode enter your MPIN"

        }
    }
    
    var buttonTitle: String {
        switch self {
        case .create: return "Create MPIN"
        case .enable: return "Enter"
        case .disable: return "Enter"

        }
    }
}

//PARENT MODE
//     │
//     │ Switch ON
//     ▼
//Is MPIN configured?
//│           │
//No          Yes
//│           │
//▼           ▼
//Create MPIN   Set Timer
//│           │
//│           ▼
//│       Enter MPIN
//│           │
//│           ▼
//│      Enable Child Mode API
//│           │
//│           ▼
//│      CHILD MODE
//│
//└── stay Parent Mode
//
//
//CHILD MODE
// │
//┌───────┴────────┐
//│                │
//Timer running       Timer expires
//│                │
//┌─────┴─────┐          │
//│           │          ├── End Game if active
//Game        Switch OFF    │
//│           │          ▼
//│           ▼      MPINViewController
//│      Disable API       │
//│           │            ▼
//│      Parent Mode   Parent Reauth API
//│                         │
//│                    ┌────┴────┐
//│                  Failure   Success
//│                    │          │
//│                 Stay MPIN    ▼
//│                         Parent Mode
//│
//└── Timer expires
//│
//▼
//End Game API
//│
//▼
//MPIN reauth
