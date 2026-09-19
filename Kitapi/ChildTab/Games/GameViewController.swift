//
//  GameViewController.swift
//  Kitapi
//
//  Created by Suneel on 04/09/26.
//

import UIKit
import FloatingPanel

class GameViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var childHeaderView: ChildHeaderView!
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var gamesTitleLabel: UILabel!
    
    @IBOutlet weak var gamesCV: UICollectionView!
    
    private let gameViewModel = GamesViewModel()
    private var games: [Game] = []
    private var gameURL: String = ""

    private var floatingPanel: FloatingPanelController?
    
    
    private var gameColorsByID: [String: UIColor] = [:]
    private let gameColors: [UIColor] = [.bluePrimaryColor,  .redPrimaryColor, .greenPrimaryColor, .orangePrimaryColor, .purplePrimaryColor, .yellowPrimaryColor, .brownPrimaryColor]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGamesScreenUI()
        self.bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getGamesInfo()
    }
    
    private func getGamesInfo() {
        Task {
            guard let childId = ChildSessionManager.shared.selectedChild?.id else {
                return
            }
            await self.gameViewModel.getAllGames(childId: childId)
        }
    }
    
    private func startGame(gameId: String) {
        Task {
            guard let childId = ChildSessionManager.shared.selectedChild?.id else {
                return
            }
            await self.gameViewModel.startGame(gameId: gameId, childId: childId)
        }
    }
    
    private func bindViewModel() {
        
        self.gameViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.gameViewModel.onGetGamesError = { [weak self] errorText in
            guard let self = self else { return }
            MessageManager.shared.show(message: errorText)
        }
        
        self.gameViewModel.onGetGamesSuccess = { [weak self] gamesResp in
            guard let self = self else { return }
            self.games = gamesResp.data.games
            self.childHeaderView.coinsLabel.text = (String(describing: gamesResp.data.childDetails?.coinBalance ?? 0) ) + " Coins"
            self.gamesCV.reloadData()
        }
        
        self.gameViewModel.onStartGameError = { [weak self] errorText in
            guard let self = self else { return }
            MessageManager.shared.show(message: errorText)
        }
        
        self.gameViewModel.onStartGameSuccess = { [weak self] gamesResp in
            guard let self = self else { return }
            guard let gameReq = gamesResp.data.gameRequest else { return }
            ChildSessionManager.shared.setGameActive(true)
            self.navigateToPlayGameVC(gameRequest: gameReq)
        }
    }
    
    fileprivate func navigateToPlayGameVC(gameRequest: GameRequest) {
        guard let vc = VCManager.openPlayGameVC() else {
            return
        }
        vc.hidesBottomBarWhenPushed = false
        vc.gameRequest = gameRequest
        vc.gameURL = self.gameURL
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


//MARK: DELEGATES

extension GameViewController: DisableChildModeDelegate {

    func didDisableChildModeSuccessfully() {

        ChildSessionManager.shared.clearChildModeSession()
        ChildManager.shared.isChildMode = false
        
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        
        // Navigate/switch to Parent Mode
        self.navigateToParentMode()
    }
    
    fileprivate func navigateToParentMode() {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
              let vc = VCManager.openTabBarVC() else {
            return
        }
        sceneDelegate.window?.rootViewController = vc
    }
}

//MARK: UICOLLECTION VIEW DELEGATES

extension GameViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let gameCell = collectionView.dequeueReusableCell(withReuseIdentifier: GamesCVCell.reUseIdentifier, for: indexPath) as? GamesCVCell else { return UICollectionViewCell()
        }
        let game = self.games[indexPath.item]
        let color = self.colorForGame(id: game.id)
        self.gameURL = game.htmlUrl?.url ?? ""
        
        gameCell.populateGameCell(games: game, color: color)
        gameCell.onPlayButtonTapped = {
            self.startGame(gameId: game.id)
        }
        return gameCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width/2 - 20, height: 215)
    }
    
    // Section insets (padding around cells)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
    
    // Spacing between cells vertically
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}


//MARK: 04/09

extension GameViewController {
    
    private func colorForGame(id: String) -> UIColor {
        
        if let existingColor = self.gameColorsByID[id] {
            return existingColor
        }
        
        let newColor = self.gameColors.randomElement() ?? .systemBlue
        gameColorsByID[id] = newColor
        
        return newColor
    }
    
    private func setGamesScreenUI() {
        self.setGameListCV()
        
        self.appBGView.backgroundColor = .pinkPrimaryColor.withAlphaComponent(0.08)
        
        self.gamesTitleLabel.textAlignment = .left
        self.gamesTitleLabel.font = UIFont(name: Fonts.bagelFatOne, size: 28)
        self.gamesTitleLabel.textColor = .headerLabekColor
        self.gamesTitleLabel.numberOfLines = 1
        self.gamesTitleLabel.text = "Games"
        
        self.childHeaderView.onToggleParentMode = { [weak self] iSwitchsOn in
            guard !iSwitchsOn else {
                return
            }
            self?.showMPINPanel()
        }
    }
    
    private func showMPINPanel() {
        guard let contentVC = VCManager.openMPINVC() else { return }
        contentVC.disableDelegate = self
        contentVC.mode = .disable
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.52)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func presentFloatingPanel(with contentVC: UIViewController, layout: FloatingPanelLayout) {
        guard floatingPanel == nil else { return }
        
        let fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        
        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false
        fpc.layout = layout
        fpc.isRemovalInteractionEnabled = true
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        fpc.contentMode = .fitToBounds
        
        self.floatingPanel = fpc
        self.present(fpc, animated: true)
    }
    
    private func setGameListCV() {
        self.gamesCV.dataSource = self
        self.gamesCV.delegate = self
        self.gamesCV.showsVerticalScrollIndicator = false
        self.gamesCV.register(GamesCVCell.nibFile, forCellWithReuseIdentifier: GamesCVCell.reUseIdentifier)
    }
    
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicatorView.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.activityIndicatorView.stopAnimating()
        self.view.sendSubviewToBack(self.activityView)
    }
    
}



extension GameViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
