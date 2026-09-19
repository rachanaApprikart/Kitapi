//
//  GoalDetailViewController.swift
//  Kitapi
//
//  Created by Suneel on 31/08/26.
//

import UIKit
import FloatingPanel

class GoalDetailViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var goalAnalyticsView: UIView!
    @IBOutlet weak var numberOfChoresLabel: UILabel!
    @IBOutlet weak var goalPercentageLabel: UILabel!
    
    @IBOutlet weak var assignedChoresCV: UICollectionView!
    @IBOutlet weak var updateGoalStatusView: UIStackView!
    @IBOutlet weak var acceptBGView: UIView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectBGView: UIView!
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var showStatusMesageLabel: UILabel!

    private var floatingPanel: FloatingPanelController?
    var goalId: String = ""
    
    private let goalDetailViewModel = GoalDetailViewModel()
    private var goalDetails: GoalDetails?
    weak var delegate: GoalRefreshDelegate?

    static var sbIdentifier: String {
        return String(describing: GoalDetailViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGoalDetailScreenUI()
        self.bindViewModel()
        self.fetchGoalDetails()
    }
    
    @IBAction func acceptAction(_ sender: UIButton) {
        self.updateGoalStatus(status: .completed, reason: nil)
    }
    
    @IBAction func rejectAction(_ sender: UIButton) {
        self.updateGoalStatus(status: .rejected, reason: "Goal rejected")
        
    }
    
    private func fetchGoalDetails() {
        Task {
            await self.goalDetailViewModel.getGoalDetails(goalId: goalId)
        }
    }
    
    private func updateGoalStatus(status: ChoreStatus, reason: String?) {
        
        guard
            let childId = ChildManager.shared.selectedChild?.id,
            let goalId = self.goalDetails?.id
        else {
            return
        }
        
        self.goalDetailViewModel.goalID = goalId
        self.goalDetailViewModel.childID = childId
        self.goalDetailViewModel.status = status
        self.goalDetailViewModel.reason = reason
        
        Task {
            await self.goalDetailViewModel.updateGoalStatus()
        }
    }
    
    

    private func bindViewModel() {
        
        self.goalDetailViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.goalDetailViewModel.onGetGoalDetailError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.goalDetailViewModel.onGetGoalDetailSuccess = { [weak self] goalDetail in
            guard let self = self else { return }
            self.goalDetails = goalDetail.data
            self.updateGoalDetailsUI()
            self.assignedChoresCV.reloadData()
        }
        
        self.goalDetailViewModel.onGoalStatusUpdateFailure = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.goalDetailViewModel.onGoalStatusUpdateSuccess = { [weak self] updatedChoreList in
            guard let self = self else { return }
            MessageManager.shared.show(message: updatedChoreList.message, type: .success)
            self.delegate?.refreshGoals()
        }
    }
    
    private func updateGoalDetailsUI() {
        guard let detail = self.goalDetails else { return }
        self.headerLabel.text = detail.title
        
        let totalTask = "\(detail.progress.totalTasks ?? 0)"
        let completedTask = "\(detail.progress.completedTasks ?? 0)"
        self.numberOfChoresLabel.text = completedTask + "/" + totalTask + " Chores"
        self.goalPercentageLabel.text = "\(Int(detail.progress.percentage ?? 0))% Completed"
        
        // status
        switch detail.status {
            
        case .pending, .upcoming:
            self.showUpdateChoreStatusView()
        
            
        case .completed:
            self.displayStatusMesageLabel()
            
            self.showStatusMesageLabel.text = "Goal is approved"
            self.showStatusMesageLabel.textColor = .greenPrimaryColor
            
            
        case .rejected:
            self.displayStatusMesageLabel()
            
            self.showStatusMesageLabel.text = "Goal is rejected"
            self.showStatusMesageLabel.textColor = .redPrimaryColor
            
        case .overdue:
            self.displayStatusMesageLabel()
            
            self.showStatusMesageLabel.text =  "Goal is overdue"
            self.showStatusMesageLabel.textColor = .orangePrimaryColor
            
        default:
            break
        }
    }
}

//MARK: ONCE ASSIGNED CHORE STATUS IS UPDATED

extension GoalDetailViewController: ChoreUpdateDelegate {
    
    func choreUpdatedSuccessfully() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.fetchGoalDetails()
    }
}

//MARK: COLLECTION VIEW DELEGATES

extension GoalDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.goalDetails?.tasks.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let listCVCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreListCVCell.reUseIdentifier, for: indexPath) as? ChoreListCVCell else {
            return UICollectionViewCell() }
        
        guard let taskDetail = self.goalDetails?.tasks[indexPath.item] else { return listCVCell }
        listCVCell.configureAssignedTasks(with: taskDetail)
        return listCVCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let taskId = self.goalDetails?.tasks[indexPath.item].id else { return }
        self.showChoreDetailsVC(choreId: taskId)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.frame.width - 40, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header2CVReusableView.reUseIdentifier, for: indexPath) as? Header2CVReusableView else {
            return UICollectionReusableView()
        }
        headerView.headerLabel.text = "Assigned Chores"
        return headerView
    }
}


extension GoalDetailViewController {
    
    private func setGoalDetailScreenUI() {
        self.setAssignedChoreListCV()
        self.headerLabel.text = ""
        self.headerLabel.textAlignment = .left
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 20)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.numberOfChoresLabel.textAlignment = .left
        self.numberOfChoresLabel.textColor = .textColor
        self.numberOfChoresLabel.numberOfLines = 1
        self.numberOfChoresLabel.font = UIFont(name: Fonts.urbanistBold, size: 12)
        self.numberOfChoresLabel.text = ""
        
        self.goalPercentageLabel.textAlignment = .left
        self.goalPercentageLabel.textColor = .greenPrimaryColor
        self.goalPercentageLabel.numberOfLines = 1
        self.goalPercentageLabel.font = UIFont(name: Fonts.urbanistBold, size: 12)
        self.goalPercentageLabel.text = ""
        
        self.goalAnalyticsView.layer.borderWidth = 1
        self.goalAnalyticsView.layer.borderColor = UIColor.gradientColor1.cgColor
        self.goalAnalyticsView.layer.cornerRadius = 15
        self.goalAnalyticsView.backgroundColor = .lightYellowPrimaryColor
        
        self.acceptBGView.layer.cornerRadius = 12.5
        self.rejectBGView.layer.cornerRadius = 12.5
        self.acceptBGView.backgroundColor = .greenPrimaryColor
        self.rejectBGView.backgroundColor = .redPrimaryColor
        
        self.acceptButton.backgroundColor = .greenPrimaryColor.withAlphaComponent(0.08)
        self.acceptButton.layer.cornerRadius = 10
        self.acceptButton.setTitle(APPConstants.approveTitle, for: .normal)
        self.acceptButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.acceptButton.setTitleColor(.buttonTitleColor, for: .normal)
        self.acceptButton.layer.borderWidth = 0.5
        self.acceptButton.layer.borderColor = UIColor.buttonBorderColor.cgColor
        
        self.rejectButton.backgroundColor = .redPrimaryColor.withAlphaComponent(0.08)
        self.rejectButton.setTitle(APPConstants.rejectTitle, for: .normal)
        self.rejectButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.rejectButton.setTitleColor(.buttonTitleColor, for: .normal)
        self.rejectButton.layer.cornerRadius = 10
        self.rejectButton.layer.borderWidth = 0.5
        self.rejectButton.layer.borderColor = UIColor.buttonBorderColor.cgColor

        self.showStatusMesageLabel.text = ""
        self.showStatusMesageLabel.textAlignment = .center
        self.showStatusMesageLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.showStatusMesageLabel.numberOfLines = 1
    }
    
    private func setAssignedChoreListCV() {
        self.assignedChoresCV.dataSource = self
        self.assignedChoresCV.delegate = self
        self.assignedChoresCV.showsVerticalScrollIndicator = false
        self.assignedChoresCV.register(ChoreListCVCell.nibFile, forCellWithReuseIdentifier: ChoreListCVCell.reUseIdentifier)
        self.assignedChoresCV.register(Header2CVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header2CVReusableView.reUseIdentifier)
    }
    
    private func showChoreDetailsVC(choreId: String) {
        guard let contentVC = VCManager.openChoreDetailsVC() else { return }
        contentVC.choreId = choreId
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
    
    private func showUpdateChoreStatusView(){
        
        self.updateGoalStatusView.isHidden = false
        self.view.bringSubviewToFront(self.updateGoalStatusView)
        
        self.showStatusMesageLabel.isHidden = true
        self.view.sendSubviewToBack(self.showStatusMesageLabel)
    }
    
    private func displayStatusMesageLabel(){
        
        self.showStatusMesageLabel.isHidden = false
        self.view.bringSubviewToFront(self.showStatusMesageLabel)
        
        self.updateGoalStatusView.isHidden = true
        self.view.sendSubviewToBack(self.updateGoalStatusView)
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

extension GoalDetailViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
