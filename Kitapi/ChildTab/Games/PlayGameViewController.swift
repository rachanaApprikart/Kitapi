//
//  PlayGameViewController.swift
//  Kitapi
//
//  Created by Suneel on 07/09/26.
//

import UIKit
import WebKit
import FloatingPanel

class PlayGameViewController: UIViewController {
    
    @IBOutlet weak var gameWebView: WKWebView!
    
    private var floatingPanel: FloatingPanelController?
    private let playGameViewModel = PlayGameViewModel()
    private var endGameReason: EndGameReason?
    private var hasFiredEndGameForExpiry = false   // renamed/repurposed from hasHandledTimerExpiry
    
    var gameURL: String = ""
    var gameRequest: GameRequest?
    
    static var sbIdentifier: String {
        return String(describing: PlayGameViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadGame()
        self.bindViewModel()
        self.observeExpiryNotifications()
        
        // Game is now active.
        ChildSessionManager.shared.setGameActive(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Safety check:
        // If the timer expired before this controller
        // became visible, handle it immediately.
        if ChildSessionManager.shared.isChildModeExpired {
            self.handleChildModeTimerExpired()
        } else if ChildSessionManager.shared.remainingSeconds <= 3 {
            self.handleChildModeAboutToExpire()
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.showQuitGamesVC()
    }
    
    // MARK - Game Loading
    
    private func loadGame() {
        guard let url = URL(string: self.gameURL) else {
            return
        }
        let request = URLRequest(url: url)
        self.gameWebView.load(request)
    }
    
    // MARK - Expiry Observers
    
    private func observeExpiryNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChildModeAboutToExpire),
            name: .childModeAboutToExpire,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChildModeTimerExpired),
            name: .childModeTimerExpired,
            object: nil
        )
    }
    
    @objc private func handleChildModeAboutToExpire() {
        guard !self.hasFiredEndGameForExpiry else { return }
        guard ChildSessionManager.shared.isGameActive else { return }
        
        guard let requestId = gameRequest?.id else { return }
        
        self.hasFiredEndGameForExpiry = true
        self.endGameSession(requestId: requestId, reason: .timerExpired)
    }
    
    // Fires at actual expiry (t=0) — purely handles navigation/handoff now.
    // Does NOT call end-game again; that already happened in the buffer window.
    @objc private func handleChildModeTimerExpired() {
        // Dismiss any open quit-confirmation panel — no point asking
        // "quit?" once time has run out.
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        
        guard ChildSessionManager.shared.isGameActive else {
            // Already cleaned up (e.g. end-game succeeded and cleared it
            // during the buffer window) — nothing more to do here.
            return
        }
        
        // Buffer call never fired (e.g. session had < 3s left when this
        // screen first appeared, or gameRequest was nil) — fall back to
        // ending/cleaning up now, same as before.
        ChildSessionManager.shared.setGameActive(false)
        NotificationCenter.default.post(name: .activeGameEndedAfterChildModeExpiry, object: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK - End Game
    
    private func endGameSession(requestId: String, reason: EndGameReason) {
        self.endGameReason = reason
        
        //    let scope: TokenScope = (reason == .manualQuit) ? .parent : .child
        
        Task { [weak self] in
            guard let self = self else { return }
            await self.playGameViewModel.engGameRequest(requestId: requestId, tokenScope: .parent)
        }
    }
    
    private func bindViewModel() {
        
        self.playGameViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            
        }
        
        self.playGameViewModel.onEndGamesError = { [weak self] errorText in
            guard let self = self else { return }
            
            switch self.endGameReason {
                
            case .manualQuit:
                MessageManager.shared.show(message: errorText)
                
            case .timerExpired:
                print("End game failed after timer expiry: \(errorText)")
                self.finishTimerExpiredFlow()
                
            case .none:
                break
            }
        }
        
        self.playGameViewModel.onEndGamesSuccess = { [weak self] response in
            guard let self = self else { return }
            
            switch self.endGameReason {
            case .manualQuit:
                MessageManager.shared.show(message: response.message, type: .success)
                ChildSessionManager.shared.setGameActive(false)
                self.navigationController?.popViewController(animated: true)
                
            case .timerExpired:
                self.finishTimerExpiredFlow()
                
            case .none:
                break
            }
        }
    }
    // Called once end-game (fired during the buffer window) resolves,
    // whether success or failure. Marks the game inactive and notifies
    // ChildTabViewController — but only pops if we're already at/past
    // actual expiry; otherwise waits, since the countdown may still show
    // a couple of seconds and popping early would look abrupt.
    private func finishTimerExpiredFlow() {
        ChildSessionManager.shared.setGameActive(false)
        
        if ChildSessionManager.shared.isChildModeExpired {
            NotificationCenter.default.post(name: .activeGameEndedAfterChildModeExpiry, object: nil)
            self.navigationController?.popViewController(animated: true)
        }
        // else: real expiry hasn't hit yet — handleChildModeTimerExpired()
        // will run shortly and, seeing isGameActive == false now, will
        // just post + pop cleanly without attempting end-game again.
    }
    
    deinit {
        ChildSessionManager.shared.setGameActive(false)
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: DELEGATE ON MANUAL QUIT

extension PlayGameViewController: QuitGameDelegate {
    
    func didTapContinueGame() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
    }
    
    func didTapQuitGame() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        
        guard let requestId = gameRequest?.id else {
            return
        }
        self.endGameSession(requestId: requestId, reason: .manualQuit)
    }
    
    private func showQuitGamesVC() {
        guard let contentVC = VCManager.openQuitGameVC() else { return }
        contentVC.delegate = self
        guard floatingPanel == nil else { return }
        
        let fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false
        
        fpc.layout = FloatingPanelCustomLayout(state: .half, inset: 0.3)
        
        fpc.isRemovalInteractionEnabled = false
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
        
        self.floatingPanel = fpc
        self.present(fpc, animated: true)
    }
}

extension PlayGameViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
    // Tracks why endGame was triggered, so the shared success/error
        // closures can react appropriately without duplicating API logic.
        private enum EndGameReason {
            case manualQuit
            case timerExpired
        }
}


//Expiry
// ↓
//Is game active?
// ↓
//YES
// ↓
//Wait
// ↓
//Game finishes
// ↓
//activeGameEndedAfterChildModeExpiry
// ↓
//Show MPIN
