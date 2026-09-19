//
//  ChildManager.swift
//  Kitapi
//
//  Created by Suneel on 01/06/26.
//

import Foundation

final class ChildManager {
    
    static let shared = ChildManager()
    private init() {}
    
    private(set) var children: [Child] = []
    
    var selectedChild: Child? {
        didSet {
            NotificationCenter.default.post(
                name: .childDidChange,
                object: selectedChild
            )
        }
    }
    
    var isChildMode: Bool {
        get {
            AppUserDefaults.isChildMode
        }

        set {
            AppUserDefaults.isChildMode = newValue

            NotificationCenter.default.post(
                name: .childModeDidChange,
                object: newValue
            )
        }
    }
    
    var childModeExpiryDate: Date? {
        AppUserDefaults.childModeExpiryDate
    }

    var isChildModeExpired: Bool {
        guard let expiryDate = childModeExpiryDate else {
            return false
        }

        return Date() >= expiryDate
    }
    
    func setChildren(_ children: [Child]) {
        self.children = children
        // Auto select first child if none selected
        if selectedChild == nil {
            selectedChild = children.first
        }
    }
    
    func clearChildModeSession() {
        AppUserDefaults.childModeExpiryDate = nil
        self.isChildMode = false
    }
    
    func clearChildMode() {
        ChildSessionManager.shared.clearChildModeSession()
        self.isChildMode = false
    }
}

extension Notification.Name {
    static let childDidChange = Notification.Name("childDidChange")
    static let childModeDidChange = Notification.Name("childModeDidChange")
    static let childModeTimerExpired = Notification.Name("childModeTimerExpired")
    static let activeGameEndedAfterChildModeExpiry = Notification.Name("activeGameEndedAfterChildModeExpiry")
    static let childModeAboutToExpire = Notification.Name("childModeAboutToExpire") // NEW

}
