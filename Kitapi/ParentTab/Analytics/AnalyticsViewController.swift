//
//  AnalyticsViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
// 6-8

import UIKit
import FloatingPanel

class AnalyticsViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerView: PersistentHeaderView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var coinsView: UIView!
    @IBOutlet weak var coinsLabel: UILabel!
    
    @IBOutlet weak var totalCoinsTitleLabel: UILabel!
    @IBOutlet weak var totalCoinsLabel: UILabel!
    @IBOutlet weak var totalCoinsView: UIView!
    

    @IBOutlet weak var analyticsCV: UICollectionView!
    
    private let analyticsViewModel = AnalyticsViewModel()

    private var floatingPanel: FloatingPanelController?
    private var analyticsData: AnalyticsData? = nil
    private var visibleSections: [AnalyticsSection] = [.chores]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAnalyticsScreenUI()
        self.bindViewModel()
        self.getAnalyticsInfo()
        self.updateUIForSelectedChild()
    }
    
    private func getMPINStatus() {
        Task {
            await self.analyticsViewModel.checkMPINStatus()
        }
    }
    
    private func getAnalyticsInfo() {
        Task {
            guard let childId = ChildManager.shared.selectedChild?.id else { return }
            await self.analyticsViewModel.getAnalyticsInfo(childId: childId)
        }
    }
    
    private func bindViewModel() {
        
        self.analyticsViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.analyticsViewModel.onCheckMPINStatusSuccess = { [weak self] mpinDetail in
            guard let self = self else { return }
            MPINManager.shared.update(with: mpinDetail.data)
        }
        
        self.analyticsViewModel.onCheckMPINStatusError = { [weak self] errorText in
            guard let self = self else { return }
            MessageManager.shared.show(message: errorText)
        }
        
        self.analyticsViewModel.onGetAnalyticsError = { [weak self] errorText in
            guard let self = self else { return }
            MessageManager.shared.show(message: errorText)
        }
        
        self.analyticsViewModel.onGetAnalyticsSuccess = { [weak self] analytics in
            guard let self = self else { return }
            self.analyticsData = analytics.data
            self.totalCoinsLabel.text = (String(describing: self.analyticsData?.coinStats?.totalEarned ?? 0) )
            self.coinsLabel.text = (String(describing: self.analyticsData?.coinStats?.currentBalance ?? 0) ) + " Coins"
            
            // Chores is always visible
            self.visibleSections = [.chores]
            let currentGoals = self.analyticsData?.currentGoals ?? []
            
            // Show Goals section only when gift goals exist
            if currentGoals.contains(where: { $0.goalType == .gift }) {
                self.visibleSections.append(.goals)
            }
            
            // Show Milestones section only when milestone goals exist
            if currentGoals.contains(where: { $0.goalType == .milestone }) {
                self.visibleSections.append(.milestones)
            }
            self.analyticsCV.reloadData()
        }
    }
    
    private func updateUIForSelectedChild() {
        guard let child = ChildManager.shared.selectedChild else {
            self.subtitleLabel.text = ""
            return
        }
        self.subtitleLabel.text = "Look how \(child.name) is doing"
        self.coinsLabel.text = "Coins"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

//MARK: PROTOCOLS AND DELEGATES

extension AnalyticsViewController: CreateMPINDelegate {
   //Incase if mpin is created in analytics tab, to refresh the status
    func mpinCreatedSuccessfully() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.getMPINStatus()
    }
}

//MARK: COLLECTION VIEW METHODS 23-8

extension AnalyticsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.visibleSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = self.visibleSections[section]
        
        switch sectionType {
            
        case .chores:
            return 1
            
        case .goals:
            return 1
            
        case .milestones:
            
            return self.analyticsData?.currentGoals.filter {
                $0.goalType == .milestone
            }.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = self.visibleSections[indexPath.section]
        
        switch sectionType {
            
        case .chores:
            
            guard let choreOverViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreAnalyticsCVCell.reUseIdentifier, for: indexPath) as? ChoreAnalyticsCVCell else {
                return UICollectionViewCell() }
            
            guard let choreCount = self.analyticsData?.choreCounts, let chorePercentage = self.analyticsData?.chorePercentages else {
                return choreOverViewCell
            }
            choreOverViewCell.configureAnalyticsCell(count: choreCount, percentage: chorePercentage)
            return choreOverViewCell
            
        case .goals:
            
            guard let goalOverViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: GoalsOverviewCVCell.reUseIdentifier, for: indexPath) as? GoalsOverviewCVCell else {
                return UICollectionViewCell() }
            
            guard let goalsCount = self.analyticsData?.goalCounts, let goalData = self.analyticsData?.currentGoals else {
                return goalOverViewCell
            }
            goalOverViewCell.configureGoalsAnalyticsCell(count: goalsCount, goalData: goalData)
            return goalOverViewCell
            
        case .milestones:
            
            guard let mileStoneCell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarCVCell.reUseIdentifier, for: indexPath) as? AvatarCVCell else {
                return UICollectionViewCell() }
            
            guard let milestone = self.analyticsData?.currentGoals.filter({ $0.goalType == .milestone }) else {
                return mileStoneCell // or whatever fallback makes sense here
            }
            
            
            //            guard let milestone = self.analyticsData?.currentGoals.filter({
            //                $0.goalType == .milestone && $0.status == .completed
            //            }) else {
            //                return UICollectionViewCell()
            //           }
            
            let mileData = milestone[indexPath.item]
            mileStoneCell.populateMilestoneCell(milestoneData: mileData)
            return mileStoneCell
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header2CVReusableView.reUseIdentifier, for: indexPath) as? Header2CVReusableView else {
            return UICollectionReusableView()
        }
        let section = self.visibleSections[indexPath.section]
        headerView.headerLabel.text = section.headerTitle
        return headerView
    }
    
    
    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }
            
            let section = self.visibleSections[sectionIndex]
            
            switch section {
                
            case .chores:
                return self.makeChoresSection()
                
            case .goals:
                return self.makeGoalsOverviewSection()
                
            case .milestones:
                return self.milestoneSection()
            }
        }
    }
    
    private func makeChoresSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(140)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }
    
    private func makeGoalsOverviewSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(220)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }
    
    private func milestoneSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(75),
            heightDimension: .estimated(75)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }
    
    private func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(50)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
    
}

//01-06

extension AnalyticsViewController {
    
    private func setAnalyticsScreenUI() {
        self.appBGView.setGradientBackground()
        self.setAnalyticsListCV()
        self.headerView.onChildSelectionTapped = { [weak self] in
            self?.showChildSelectionPanel()
        }
        
        self.headerView.onToggleChildMode = { [weak self]  isSwitchOn in
            self?.childModeButtonTapped()
        }
        
        //To observe change in child selection, so that UI and API can be refreshed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onChildChanged),
            name: .childDidChange,
            object: nil
        )
        self.coinsView.layer.cornerRadius = 12
        self.totalCoinsView.layer.cornerRadius = 12
        self.totalCoinsView.layer.borderWidth = 0.5
        self.totalCoinsView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        
        self.titleLabel.textColor = .headerLabekColor
        self.titleLabel.textAlignment = .left
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont(name: Fonts.urbanistBold, size: 24)
        self.titleLabel.text = "Analytics"

        self.totalCoinsTitleLabel.textColor = .headerLabekColor
        self.totalCoinsTitleLabel.textAlignment = .left
        self.totalCoinsTitleLabel.numberOfLines = 1
        self.totalCoinsTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.totalCoinsTitleLabel.text = APPConstants.allTimeCoinsTitle
        
        self.totalCoinsLabel.textColor = .textColor
        self.totalCoinsLabel.textAlignment = .left
        self.totalCoinsLabel.numberOfLines = 1
        self.totalCoinsLabel.font = UIFont(name: Fonts.urbanistBlack, size: 14)
        self.totalCoinsLabel.text = ""

        self.subtitleLabel.textColor = .headerLabekColor
        self.subtitleLabel.textAlignment = .left
        self.subtitleLabel.numberOfLines = 1
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 12)
        
        self.coinsLabel.textColor = .black
        self.coinsLabel.textAlignment = .left
        self.coinsLabel.numberOfLines = 1
        self.coinsLabel.font = UIFont(name: Fonts.urbanistBlack, size: 14)
    }
    
    //Mostly it will fetch mpinStatus in homeVC. Incase if MPIN is created in analyticsVC, the delegate has to refresh the status. hence getMPINStatus
    
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
    
    @objc private func onChildChanged() {
        self.updateUIForSelectedChild()
        self.getAnalyticsInfo()
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
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showMPINPanel() {
        guard let contentVC = VCManager.openMPINVC() else { return }
        contentVC.delegate = self
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
    
    private func setAnalyticsListCV() {
        self.analyticsCV.dataSource = self
        self.analyticsCV.delegate = self
        self.analyticsCV.showsVerticalScrollIndicator = false
        self.analyticsCV.collectionViewLayout = self.makeLayout()

        self.analyticsCV.register(ChoreAnalyticsCVCell.nibFile, forCellWithReuseIdentifier: ChoreAnalyticsCVCell.reUseIdentifier)
        self.analyticsCV.register(GoalsOverviewCVCell.nibFile, forCellWithReuseIdentifier: GoalsOverviewCVCell.reUseIdentifier)
        self.analyticsCV.register(AvatarCVCell.nibFile, forCellWithReuseIdentifier: AvatarCVCell.reUseIdentifier)
        
        self.analyticsCV.register(Header2CVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header2CVReusableView.reUseIdentifier)
    }
}


extension AnalyticsViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
