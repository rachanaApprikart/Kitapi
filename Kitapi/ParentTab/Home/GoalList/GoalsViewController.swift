//
//  GoalsViewController.swift
//  Kitapi
//
//  Created by Suneel on 21/05/26.
// 24-08

import UIKit
import FloatingPanel

class GoalsViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var goalView: UIView!
    @IBOutlet weak var goalTitleLabel: UILabel!
    @IBOutlet weak var goalSubtitleLabel: UILabel!
    @IBOutlet weak var addGoalButton: UIButton!

    @IBOutlet weak var noGoalView: UIView!
    @IBOutlet weak var noGoalSubtitleLabel: UILabel!
    @IBOutlet weak var noGoalTitleLabel: UILabel!
    @IBOutlet weak var addGoalBtnInNoChoreView: UIButton!
    
    @IBOutlet weak var goalListCV: UICollectionView!
    
    private let goalsViewModel = GoalsViewModel()
    private var floatingPanel: FloatingPanelController?
    
    private var giftGoals: [GoalData] = []
    private var milestoneGoals: [GoalData] = []
    private var selectedGoalId: String?
    
    static var sbIdentifier: String {
        return String(describing: GoalsViewController.self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGoalsVCUI()
        self.bindViewModel()
        self.updateUIForSelectedChild()
        self.fetchGoalsForSelectedChild()
    }
    
    @IBAction func addGoalActionInNoGoalView(_ sender: UIButton) {
        self.showCreateGoalVC()
    }
    
    @IBAction func addCGoalAction(_ sender: UIButton) {
        self.showCreateGoalVC()
    }
    
    private func fetchGoalsForSelectedChild() {
        guard let childId = ChildManager.shared.selectedChild?.id else { return }
        
        Task {
            await self.goalsViewModel.fetchAllGoals(childId: childId)
        }
    }
    
    private func assignTaskToGoals(taskId: [String]) {
        guard let goalId = self.selectedGoalId else {
            return
        }
        Task {
            await self.goalsViewModel.updateByAssigningTask(id: taskId, goalId: goalId)
        }
    }
    
    private func bindViewModel() {
        
        self.goalsViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.goalsViewModel.onErrorToGetAllGoals = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.goalsViewModel.onGetAllGoalsSuccess = { [weak self] goalList, milestoneList in
            guard let self = self else { return }
            
            self.giftGoals = goalList.data.goals
            self.milestoneGoals = milestoneList.data.goals
            
            let hasGiftGoals = !self.giftGoals.isEmpty
            let hasMilestoneGoals = !self.milestoneGoals.isEmpty
            
            if !hasGiftGoals && !hasMilestoneGoals {
                self.showNoGoalView()
            } else {
                self.hideNoGoalView()
            }
            self.goalListCV.reloadData()
        }
        
        self.goalsViewModel.onUpdateGoalByAssigningTaskFailure = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.goalsViewModel.onUpdateGoalByAssigningTaskSuccess = { [weak self] updateResp in
            guard let self = self else { return }

            MessageManager.shared.show(message: updateResp.message, type: .success)
            self.floatingPanel?.dismiss(animated: true)
            self.floatingPanel = nil
            self.selectedGoalId = nil
            self.fetchGoalsForSelectedChild()
        }
    }
    
    @objc private func onChildChanged() {
        self.updateUIForSelectedChild()
        self.fetchGoalsForSelectedChild()
    }

    
    private func showCreateGoalVC() {
        guard let contentVC = VCManager.openCreateGoalsVC() else { return }
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.5)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }

    private func updateUIForSelectedChild() {
        guard let child = ChildManager.shared.selectedChild else {
            self.goalSubtitleLabel.text = ""
            self.noGoalSubtitleLabel.text = ""
            return
        }
        self.goalSubtitleLabel.text = "\(child.name) goals"
        self.noGoalSubtitleLabel.text = "Add goal for \(child.name)"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: ONCE Goal IS CREATED/UPDATED WITH TASK SUCCESSFULLY

extension GoalsViewController: GoalRefreshDelegate, AssignChoreDelegate {
    
    func didAssignChores(with choreIDs: [String]) {
        self.assignTaskToGoals(taskId: choreIDs)
    }
    
    func refreshGoals() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.fetchGoalsForSelectedChild()
    }
}

//MARK: collection view delegates

extension GoalsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return GoalsSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let section = GoalsSection(rawValue: section) else {
            return 0
        }
        switch section {
        case .gifts:
            return self.giftGoals.count
            
        case .milestones:
            return self.milestoneGoals.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let section = GoalsSection(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }
        
        switch section {
            
        case .gifts:
            let goal = self.giftGoals[indexPath.row]
            
            if goal.taskCount == 0 {
                
                guard let createTemplateCell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateChoreTemplateCVCell.reUseIdentifier, for: indexPath) as? CreateChoreTemplateCVCell else { return UICollectionViewCell() }
                createTemplateCell.populateAssignChoreCell(data: goal)
                
                createTemplateCell.onCreateChoreTemplateAction = {
                    self.selectedGoalId = goal.id
                    self.showAssignTaskVC()
                }
                return createTemplateCell
                
            } else {
                
                guard let goalCardCell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrentGoalCardCell.reUseIdentifier, for: indexPath) as? CurrentGoalCardCell else { return UICollectionViewCell()
                }
                
                goalCardCell.populateGoalCardCell(with: goal)
                return goalCardCell
                
            }
        case .milestones:
            guard let mileCell = collectionView.dequeueReusableCell(withReuseIdentifier: MilestoneCVCell.reUseIdentifier, for: indexPath) as? MilestoneCVCell else { return UICollectionViewCell()
            }
            
            let milestoneData = self.milestoneGoals[indexPath.row]
            mileCell.populateMilestoneCell(milestoneData: milestoneData)
            return mileCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let section = GoalsSection(rawValue: indexPath.section) else {
            return
        }
        
        switch section {
            
        case .gifts:
            
            let goal = self.giftGoals[indexPath.row]
            
            if goal.taskCount == 0 {
              
            } else {
                self.showGoalDetailsVC(goalId: goal.id)
            }
        case .milestones:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let section = GoalsSection(rawValue: indexPath.section) else {
            return .zero
        }
        
        switch section {
            
        case .gifts:
            let goal = self.giftGoals[indexPath.row]
            let height: CGFloat = goal.taskCount == 0 ? 100 : 90
            let width: CGFloat = goal.taskCount == 0 ? collectionView.bounds.width - 10 : collectionView.bounds.width - 32
            return CGSize(width: width, height: height)
            
        case .milestones:
            let width = collectionView.bounds.width - 32
            
            return CGSize(width: width, height: 90)
        }
    }
    
    // Spacing between cells vertically
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    // Header size for each section
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = GoalsSection(rawValue: section) else {
            return .zero
        }
        
        switch section {
        case .gifts:
            return self.giftGoals.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: 44)
            
        case .milestones:
            return self.milestoneGoals.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: 44)
        }
    }
    
    // Section insets (padding around cells)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header2CVReusableView.reUseIdentifier, for: indexPath) as? Header2CVReusableView else {
            return UICollectionReusableView()
        }
        
        guard let section = GoalsSection(rawValue: indexPath.section) else {
            headerView.headerLabel.text = ""
            return headerView
        }
        
        switch section {
        case .gifts:
            headerView.headerLabel.text = self.giftGoals.isEmpty ? "" : "Gifts"
            
        case .milestones:
            headerView.headerLabel.text = self.milestoneGoals.isEmpty ? "" : "Milestones"
        }
        return headerView
    }
}



extension GoalsViewController {
    
    private func setGoalsVCUI() {
        self.appBGView.setGradientBackground()
        self.setGoalListCV()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onChildChanged),
            name: .childDidChange,
            object: nil
        )
        
        
        self.goalTitleLabel.textColor = .headerLabekColor
        self.goalTitleLabel.textAlignment = .left
        self.goalTitleLabel.numberOfLines = 1
        self.goalTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 24)
        self.goalTitleLabel.text = "Goals"
        
        self.goalSubtitleLabel.textColor = .headerLabekColor
        self.goalSubtitleLabel.textAlignment = .left
        self.goalSubtitleLabel.numberOfLines = 1
        self.goalSubtitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 12)
        
        self.addGoalButton.setTitle("Add", for: .normal)
        self.addGoalButton.titleLabel?.font = UIFont(name: Fonts.urbanistExtraBold, size: 14)
        self.addGoalButton.setTitleColor(.white, for: .normal)
        self.addGoalButton.backgroundColor = .pinkPrimaryColor
        self.addGoalButton.layer.cornerRadius = 10
        
        self.noGoalTitleLabel.textColor = .headerLabekColor
        self.noGoalTitleLabel.textAlignment = .center
        self.noGoalTitleLabel.numberOfLines = 1
        self.noGoalTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 20)
        self.noGoalTitleLabel.text = "No Goals"
        
        self.noGoalSubtitleLabel.textColor = .headerLabekColor
        self.noGoalSubtitleLabel.textAlignment = .center
        self.noGoalSubtitleLabel.numberOfLines = 1
        self.noGoalSubtitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 12)
        
        self.addGoalBtnInNoChoreView.setTitle("Add Goal", for: .normal)
        self.addGoalBtnInNoChoreView.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.addGoalBtnInNoChoreView.setTitleColor(.white, for: .normal)
        self.addGoalBtnInNoChoreView.backgroundColor = .pinkPrimaryColor
        self.addGoalBtnInNoChoreView.layer.cornerRadius = 20
        
    }
    
    private func setGoalListCV() {
        self.goalListCV.dataSource = self
        self.goalListCV.delegate = self
        self.goalListCV.showsVerticalScrollIndicator = false
        self.goalListCV.register(CreateChoreTemplateCVCell.nibFile, forCellWithReuseIdentifier: CreateChoreTemplateCVCell.reUseIdentifier)
        self.goalListCV.register(Header2CVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header2CVReusableView.reUseIdentifier)
        self.goalListCV.register(CurrentGoalCardCell.nibFile, forCellWithReuseIdentifier: CurrentGoalCardCell.reUseIdentifier)
        self.goalListCV.register(MilestoneCVCell.nibFile, forCellWithReuseIdentifier: MilestoneCVCell.reUseIdentifier)
    }
    
    private func showAssignTaskVC() {
        guard let contentVC = VCManager.openAssignChoresVC() else { return }
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.8)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showGoalDetailsVC(goalId: String) {
        guard let contentVC = VCManager.openGoalDetailsVC() else { return }
        contentVC.goalId = goalId
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.8)
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
    
    private func showNoGoalView() {
        self.noGoalView.isHidden = false
        self.view.bringSubviewToFront(self.noGoalView)
        
        self.goalView.isHidden = true
        self.view.sendSubviewToBack(self.goalView)
    }
    
    private func hideNoGoalView() {
        self.noGoalView.isHidden = true
        self.view.sendSubviewToBack(self.noGoalView)

        self.goalView.isHidden = false
        self.view.bringSubviewToFront(self.goalView)
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


extension GoalsViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
