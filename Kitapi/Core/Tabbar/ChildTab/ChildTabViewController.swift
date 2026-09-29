//
//  ChildTabViewController.swift
//  Kitapi
//
//  Created by Suneel on 04/09/26.
//

import UIKit
import FloatingPanel

class ChildTabViewController: UITabBarController {

    // MARK: - Properties

    private var floatingPanel: FloatingPanelController?
    private var waitingForActiveGameToEnd = false

    static var sbIdentifier: String {
        return String(describing: ChildTabViewController.self)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTabBar()
        self.observeChildModeExpiry()
        self.observeGameEndedAfterExpiry()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Important for app relaunch.
        self.checkForExpiredChildMode()
    }
    
    func configureTabBar() {
        self.tabBar.tintColor = .pinkPrimaryColor
        self.tabBar.backgroundColor = .white
        self.selectedIndex = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



// MARK: - Child Mode Expiry

private extension ChildTabViewController {

    func observeChildModeExpiry() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChildModeTimerExpired),
            name: .childModeTimerExpired,
            object: nil
        )
    }

    func observeGameEndedAfterExpiry() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActiveGameEndedAfterExpiry),
            name: .activeGameEndedAfterChildModeExpiry,
            object: nil
        )
    }

    @objc
    func handleChildModeTimerExpired() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            // MPIN panel is already visible.
            guard self.floatingPanel == nil else {
                return
            }

            // If a game is active, let PlayGameViewController
            // end the game first.
            if ChildSessionManager.shared.isGameActive {
                self.waitingForActiveGameToEnd = true
                return
            }

            // No active game. Ask parent for MPIN immediately.
            self.showReAuthMPINPanel()
        }
    }

    @objc
    func handleActiveGameEndedAfterExpiry() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            guard self.waitingForActiveGameToEnd else {
                return
            }

            self.waitingForActiveGameToEnd = false

            // Game has finished. Now ask parent for MPIN.
            self.showReAuthMPINPanel()
        }
    }

    func checkForExpiredChildMode() {
        let sessionManager = ChildSessionManager.shared

        guard sessionManager.hasChildModeSession else {
            return
        }

        guard sessionManager.isChildModeExpired else {
            return
        }

        // App was relaunched while Child Mode was already expired.
        if sessionManager.isGameActive {
            self.waitingForActiveGameToEnd = true
            return
        }

        self.showReAuthMPINPanel()
    }
}

// MARK: - Parent Mode Navigation

extension ChildTabViewController {

    fileprivate func navigateToParentMode() {
        guard
            let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
            let vc = VCManager.openTabBarVC()
        else {
            return
        }

        sceneDelegate.window?.rootViewController = vc
    }
}

// MARK: - Re-authentication

private extension ChildTabViewController {

    func showReAuthMPINPanel() {
        guard self.floatingPanel == nil else {
            return
        }
        guard let contentVC = VCManager.openReAuthVC() else {
            return
        }
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .half,inset: 0.52)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }

    func presentFloatingPanel(with contentVC: UIViewController, layout: FloatingPanelLayout) {
        guard self.floatingPanel == nil else {
            return
        }

        let fpc = FloatingPanelController()

        fpc.delegate = self
        fpc.set(contentViewController: contentVC)

        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false

        fpc.layout = layout
        fpc.isRemovalInteractionEnabled = false
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
        fpc.contentMode = .fitToBounds

        self.floatingPanel = fpc
        self.present(fpc, animated: true)
    }
}

extension ChildTabViewController: ReAuthDelegate {
    
    func didFailReauth(message: String) {
        // No-op here — the content VC already shows its own error and stays presented.
    }
    
    func didReauthSuccessfully() {
        
        ChildSessionManager.shared.clearChildModeSession()
        ChildManager.shared.isChildMode = false
        
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        
        self.navigateToParentMode()
    }
}
    


extension ChildTabViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}


//CHILD MODE
//    │
//    ▼
//Timer running
//    │
//Timer expires
//    │
//    ▼
//Persist expired state
//    │
//    ▼
//Show Re-Auth MPIN
//    │
//┌───────────┴───────────┐
//│                       │
//MPIN incorrect          MPIN correct
//│                       │
//▼                       ▼
//Stay Child Mode        Clear Child Session
//                       isChildMode = false
//                             │
//                             ▼
//                        Parent Mode
