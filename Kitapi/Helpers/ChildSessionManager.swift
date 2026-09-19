//
//  ChildSessionManager.swift
//  Kitapi
//
//  Created by Suneel on 06/09/26
//

import Foundation

final class ChildSessionManager {

    static let shared = ChildSessionManager()

    private init() {
        self.loadSession()
    }

    // MARK: - Keys

    private enum Keys {

        static let selectedChild = "selectedChild"
        static let childModeToken = "childModeToken"
        static let childModeStartTime = "childModeStartTime"
        static let childModeSessionDuration = "childModeSessionDuration"
    }

    // MARK: - Selected Child

    private(set) var selectedChild: Child?

    // MARK: - Child Mode Session

    private(set) var childModeToken: String?
    private(set) var childModeStartTime: Date?
    private(set) var childModeSessionDuration: Int?

    var childModeExpiresAt: Date? {

        get {
            AppUserDefaults.childModeExpiryDate
        }

        set {
            AppUserDefaults.childModeExpiryDate = newValue
        }
    }
       private var hasFiredAboutToExpireWarning = false
       private let endGameBufferSeconds = 3
    var currentChildModeToken: String? {
        return self.childModeToken
    }

    // MARK: - Game State

    //True only while a game is actively running.
    private(set) var isGameActive: Bool = false

    func setGameActive(_ active: Bool) {
        self.isGameActive = active
    }

    // MARK: - Child Mode State

    var hasChildModeSession: Bool {
        childModeExpiresAt != nil
    }

    var isChildModeExpired: Bool {

        guard let expiresAt = childModeExpiresAt else {
            return false
        }

        return Date() >= expiresAt
    }

    // MARK: - Timer

    var remainingTimeInterval: TimeInterval {

        guard let expiresAt = childModeExpiresAt else {
            return 0
        }

        return max(
            0,
            expiresAt.timeIntervalSinceNow
        )
    }

    var remainingSeconds: Int {
        Int(ceil(remainingTimeInterval))
    }

    // MARK: - Expiry Monitoring

    private var expiryTimer: Timer?

    func startExpiryMonitoring() {
          self.stopExpiryMonitoring()
          self.hasFiredAboutToExpireWarning = false
          
          guard hasChildModeSession else { return }
          
          if isChildModeExpired {
              NotificationCenter.default.post(name: .childModeTimerExpired, object: nil)
              return
          }
          
          self.expiryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
              guard let self = self else { return }
              
              if !self.hasFiredAboutToExpireWarning && self.remainingSeconds <= self.endGameBufferSeconds {
                  self.hasFiredAboutToExpireWarning = true
                  NotificationCenter.default.post(name: .childModeAboutToExpire, object: nil)
              }
              
              if self.isChildModeExpired {
                  self.stopExpiryMonitoring()
                  NotificationCenter.default.post(name: .childModeTimerExpired, object: nil)
              }
          }
      }
      
      func stopExpiryMonitoring() {
          self.expiryTimer?.invalidate()
          self.expiryTimer = nil
      }
  
    private func postTimerExpiredNotification() {

        // Prevent repeated notifications.
        guard self.hasChildModeSession else {
            return
        }

        NotificationCenter.default.post(
            name: .childModeTimerExpired,
            object: nil
        )
    }

    // MARK: - Selected Child

    func updateSelectedChild(_ child: Child) {

        self.selectedChild = child

        AppUserDefaults.userDefaults.save(
            customObject: child,
            inKey: Keys.selectedChild
        )
    }

    // MARK: - Start Child Mode Session

    func startChildModeSession(
        token: String?,
        startTime: String?,
        expiresAt: String?,
        sessionDuration: String?
    ) {

        self.childModeToken = token

        self.childModeStartTime = parseDate(
            startTime
        )

        self.childModeExpiresAt = parseDate(
            expiresAt
        )

        self.childModeSessionDuration = Int(
            sessionDuration ?? ""
        )

        // Save token

        AppUserDefaults.userDefaults.set(
            token,
            forKey: Keys.childModeToken
        )

        // Save start time

        AppUserDefaults.userDefaults.set(
            self.childModeStartTime,
            forKey: Keys.childModeStartTime
        )

        // Save session duration

        AppUserDefaults.userDefaults.set(
            self.childModeSessionDuration,
            forKey: Keys.childModeSessionDuration
        )

        // Save expiry

        AppUserDefaults.childModeExpiryDate =
            self.childModeExpiresAt

        // Start monitoring immediately.
        self.startExpiryMonitoring()
    }

    // MARK: - Clear Child Mode Session

    func clearChildModeSession() {

        self.stopExpiryMonitoring()

        self.isGameActive = false

        self.childModeToken = nil
        self.childModeStartTime = nil
        self.childModeExpiresAt = nil
        self.childModeSessionDuration = nil
        self.selectedChild = nil

        AppUserDefaults.userDefaults.removeObject(
            forKey: Keys.selectedChild
        )

        AppUserDefaults.userDefaults.removeObject(
            forKey: Keys.childModeToken
        )

        AppUserDefaults.userDefaults.removeObject(
            forKey: Keys.childModeStartTime
        )

        AppUserDefaults.userDefaults.removeObject(
            forKey: Keys.childModeSessionDuration
        )

        AppUserDefaults.childModeExpiryDate = nil
    }

    // MARK: - Load Session

    private func loadSession() {

        // Restore selected child

        self.selectedChild =
            AppUserDefaults.userDefaults.retrieve(
                object: Child.self,
                fromKey: Keys.selectedChild
            )

        // Restore token

        self.childModeToken =
            AppUserDefaults.userDefaults.string(
                forKey: Keys.childModeToken
            )

        // Restore start time

        self.childModeStartTime =
            AppUserDefaults.userDefaults.object(
                forKey: Keys.childModeStartTime
            ) as? Date

        // Restore session duration

        if AppUserDefaults.userDefaults.object(
            forKey: Keys.childModeSessionDuration
        ) != nil {

            self.childModeSessionDuration =
                AppUserDefaults.userDefaults.integer(
                    forKey: Keys.childModeSessionDuration
                )
        }
    }

    // MARK: - Date Parser

    private func parseDate(
        _ value: String?
    ) -> Date? {

        guard let value = value else {
            return nil
        }

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [
            .withInternetDateTime
        ]

        return formatter.date(from: value)
    }

    deinit {
        self.stopExpiryMonitoring()
    }
}
