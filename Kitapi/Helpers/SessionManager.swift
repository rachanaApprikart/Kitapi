//
//  SessionManager.swift
//  Kitapi
//
//  Created by Suneel on 28/09/26.
//

import Foundation


final class SessionManager {

    static let shared = SessionManager()

    private init() {}

    // This property is only accessed on the main thread.
    private var isHandlingSessionExpiration = false

    func handleAuthenticationFailure() {

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            // Prevent multiple session-expired alerts
            // when several API calls return 401/403 at the same time.
            guard !self.isHandlingSessionExpiration else {
                return
            }
            self.isHandlingSessionExpiration = true
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }

    func resetSessionExpirationState() {
        DispatchQueue.main.async { [weak self] in
            self?.isHandlingSessionExpiration = false
        }
    }
}
