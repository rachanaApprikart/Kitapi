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
        didSet { if oldValue?.id != selectedChild?.id {
            // Different child selected OR selected child became nil.Chores, goals and analytics should refetch.
            
            NotificationCenter.default.post( name: .childDidChange, object: selectedChild)
        } else {
            // Same child, but latest child object received. Example: // Old name: "John" // New name: "Johnny" Only UI details need to refresh.
            
            NotificationCenter.default.post( name: .childDetailsDidUpdate, object: selectedChild)
        }
        }
    }
    
    var isChildMode: Bool {
        get {
            AppUserDefaults.isChildMode
        }
        set {
            AppUserDefaults.isChildMode = newValue
            NotificationCenter.default.post(name: .childModeDidChange, object: newValue)
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
       
        // If there is already a selected child, try to find the latest version of that same child.
        
        if let currentId = selectedChild?.id, let updatedChild = children.first(where: { $0.id == currentId }) {
            // Same child ID. This will trigger .childDetailsDidUpdate // instead of .childDidChange.
            selectedChild = updatedChild
        } else {
            // Either: // 1. No child was selected yet // 2. Previously selected child was deleted // // Select the first available child.
            selectedChild = children.first
        }
    }
    
    // MARK: - Select Child
    func selectChild(withId childId: String) {
        guard let child = children.first(where: { $0.id == childId })
        else { return }
        selectedChild = child
        
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
    static let sessionExpired = Notification.Name("sessionExpired")
    static let childDetailsDidUpdate = Notification.Name("childDetailsDidUpdate")

}
