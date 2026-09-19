//
//  HomeViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import UIKit
import FloatingPanel

class HomeViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerView: PersistentHeaderView!
    @IBOutlet weak var choresButton: UIButton!
    @IBOutlet weak var goalsButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var goalsBGView: UIView!
    @IBOutlet weak var choresBGView: UIView!
    
    private var currentVC: UIViewController?
    
    private var choresVC: ChoresViewController = {
        return VCManager.openChoresVC()!
    }()
    
    private lazy var goalsVC: GoalsViewController = {
        return VCManager.openGoalsVC()!
    }()
    
    private var currentHomeTab: HomeTab = .chores
    
    private let homeViewModel = HomeViewModel()
    private var floatingPanel: FloatingPanelController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setHomeScreenUI()
        self.bindViewModel()
        self.getMPINStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getChildrenDetails()
    }
    
    @IBAction func goalsAction(_ sender: UIButton) {
        self.currentHomeTab = .goals
        self.updateTabAppearance()
        self.switchToVC(goalsVC)
    }
    
    @IBAction func choresAction(_ sender: UIButton) {
        self.currentHomeTab = .chores
        self.switchToVC(choresVC)
        self.updateTabAppearance()
    }
    
    private func bindViewModel() {
        
        self.homeViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.homeViewModel.onError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.homeViewModel.onChildDetailsSuccess = { [weak self] parentDetails in
            guard let self = self else { return }
            
            if parentDetails.children.isEmpty {
                self.openCreateChildProfileVC()
            } else {
                //Store in singleton — available to all tabs
                ChildManager.shared.setChildren(parentDetails.children)
            }
        }
        
        self.homeViewModel.onCheckMPINStatusSuccess = { [weak self] mpinDetail in
            guard let self = self else { return }
            MPINManager.shared.update(with: mpinDetail.data)
        }
        
        self.homeViewModel.onCheckMPINStatusError = { [weak self] errorText in
            guard let self = self else { return }
            MessageManager.shared.show(message: errorText)
        }
    }
    
    private func getChildrenDetails() {
        Task {
            await self.homeViewModel.getDetailsOfChildren()
        }
    }
    
    private func getMPINStatus() {
        Task {
            await self.homeViewModel.checkMPINStatus()
        }
    }
    
    // MARK: - Tab Switching
    
    private func switchToVC(_ vc: UIViewController) {
        
        // Remove old VC
        self.currentVC?.willMove(toParent: nil)
        self.currentVC?.view.removeFromSuperview()
        self.currentVC?.removeFromParent()
        
        // Add new VC
        addChild(vc)
        
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        self.currentVC = vc
    }
    
    private func childModeButtonTapped() {
  
        if MPINManager.shared.hasFetchedStatus {
            
            if MPINManager.shared.isSetup {
                self.showSetTimerPanel()
            } else {
                self.showMPINPanel()
            }
        } else {
            self.getMPINStatus()
        }
    }
    
    
    private func openCreateChildProfileVC() {
        guard let vc = VCManager.openCreateChildProfileVC() else { return }
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: PROTOCOLS AND DELEGATES

extension HomeViewController: CreateMPINDelegate {

    func mpinCreatedSuccessfully() {

        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.getMPINStatus()
    }
}

//MARK: ------------- ui -------------

extension HomeViewController {
    
    private func setHomeScreenUI() {
        self.updateTabAppearance()
        self.switchToVC(choresVC)
        self.choresButton.layer.cornerRadius = 10
        self.goalsButton.layer.cornerRadius = 10
        
        self.goalsBGView.layer.cornerRadius = 10
        self.choresBGView.layer.cornerRadius = 10
        
        self.choresButton.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 16)
        self.goalsButton.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 16)
        
        self.headerView.onChildSelectionTapped = { [weak self] in
            self?.showChildSelectionPanel()
        }
        self.headerView.onToggleChildMode = { [weak self] isSwitchOn in
            self?.childModeButtonTapped()
        }
    }
    
    private func updateTabAppearance() {
        UIView.animate(withDuration: 0.3) {
            if self.currentHomeTab == .chores {
                self.choresButton.backgroundColor = .buttonBackgroundColor
                self.choresButton.setTitleColor(.white, for: .normal)
                self.goalsButton.backgroundColor = .gradientColor1
                self.goalsButton.setTitleColor(.headerLabekColor, for: .normal)
                self.choresBGView.backgroundColor = .gradientColor1
                self.goalsBGView.backgroundColor = .white
                
            } else {
                self.goalsButton.backgroundColor = .buttonBackgroundColor
                self.goalsButton.setTitleColor(.white, for: .normal)
                self.choresButton.backgroundColor = .gradientColor1
                self.choresButton.setTitleColor(.headerLabekColor, for: .normal)
                self.goalsBGView.backgroundColor = .gradientColor1
                self.choresBGView.backgroundColor = .white
            }
        }
    }
    
    private func showChildSelectionPanel() {
        guard let contentVC = VCManager.openChildListVC() else { return }
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.5)
        contentVC.childrenList = ChildManager.shared.children
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showSetTimerPanel() {
        guard let contentVC = VCManager.opensetTimerVC() else { return }
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.52)
        
        contentVC.onSkip = { [weak self] in
            guard let self = self else { return }
            self.floatingPanel?.dismiss(animated: true)
            self.floatingPanel = nil
         }
        
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showMPINPanel() {
        guard let contentVC = VCManager.openMPINVC() else { return }
        contentVC.delegate = self
        contentVC.mode = .create
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

extension HomeViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}

enum HomeTab {
    case chores
    case goals
}

