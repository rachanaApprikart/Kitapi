//
//  MPINManager.swift
//  Kitapi
//
//  Created by Suneel on 04/08/26.
//

import Foundation


final class MPINManager {
    
    static let shared = MPINManager()
    private init() {}
    
    private(set) var status: MPINData?
    
    // True once we've successfully received a status from the server at least once.
    // Use this to avoid trusting `isSetup`'s default before a real fetch has happened.
    
    var hasFetchedStatus: Bool {
        status != nil
    }
    
    func update(with status: MPINData) {
        self.status = status
    }
    
    // Defaults to false when status is unknown — callers that need to distinguish
    // "confirmed not set up" from "never fetched" should check `hasFetchedStatus` first.
    var isSetup: Bool {
        status?.isSetup ?? false
    }
}
//┌──────────────────────┐
//│      PARENT MODE     │
//└──────────┬───────────┘
//           │
//    MPIN verified
//           │
//           ▼
//┌──────────────────────┐
//│      CHILD MODE      │
//│   Timer running      │
//└──────────┬───────────┘
//           │
//      Timer expires
//           │
//           ▼
//┌──────────────────────┐
//│ CHILD MODE EXPIRED   │
//│ Re-auth required     │
//└──────────┬───────────┘
//           │
//      Parent MPIN
//           │
//      Reauth API
//           │
//      ┌────┴────┐
//      │         │
//   Failure    Success
//      │         │
//      ▼         ▼
//Stay Child    Parent Mode
