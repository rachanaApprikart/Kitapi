//
//  CreateGoalViewController.swift
//  Kitapi
//
//  Created by Suneel on 24/08/26.
//

import UIKit
import FloatingPanel

class CreateGoalViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var goalTypeTextfieldView: CustomTextField!
    @IBOutlet weak var milestoneTextFieldView: CustomTextField!
    @IBOutlet weak var giftNameTextfieldView: CustomTextField!
    
    @IBOutlet weak var assignChoresButton: UIButton!
    @IBOutlet weak var createGoalButton: UIButton!
    
    private var floatingPanel: FloatingPanelController?
    
    private var selectedGoalType: GoalType = .milestone
    private var selectedMilestoneAmount: Int = 100
    private var selectedTaskIds: [String] = []
    private var giftName: String = ""
    private let viewModel = CreateGoalViewModel()

    weak var delegate: GoalRefreshDelegate?

    
    static var sbIdentifier: String {
        return String(describing: CreateGoalViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setCreateGoalScreenUI()
        self.setupDefaultGoalType()
        self.bindViewModel()
    }
    
    @IBAction func assignChoresAction(_ sender: UIButton) {
        self.showAssignChoresVC()
    }
    
    @IBAction func createGoalAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.viewModel.giftName = self.giftNameTextfieldView.customTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.viewModel.childId = ChildManager.shared.selectedChild?.id ?? ""
        self.viewModel.goalType = self.selectedGoalType
        self.viewModel.taskIds = self.selectedTaskIds
        self.viewModel.milestoneAmt = self.selectedMilestoneAmount
        
        Task {
            await self.viewModel.register()
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.onValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
                
            case .giftName:
                self.giftNameTextfieldView.showError(message: error.message)
                
            default:
                break
            }
        }
        
        self.viewModel.onLoadingChanged = { [weak self] isLoding in
            guard let self = self else { return }
            isLoding ? self.showActivityIndicator() : self.hideActivityIndicator()
        
            self.createGoalButton.isEnabled = !isLoding
            self.createGoalButton.alpha = isLoding ? 0.6 : 1.0
        }
        
        self.viewModel.onCreateGoalError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewModel.onCreateGoalSuccess = { [weak self] chore in
            guard let self = self else { return }
            MessageManager.shared.show(message: chore.message, type: .success)
            self.delegate?.refreshGoals()
        }
    }
    
    private func setupDefaultGoalType() {
        self.selectedGoalType = .milestone
        self.selectedMilestoneAmount = 100

        self.updateGoalTypeUI(.milestone)
        self.updateMilestoneSelection(amount: 100)
    }
    
    private func updateGoalTypeUI(_ type: GoalType) {
        
        self.selectedGoalType = type

        switch type {

        case .gift:
            self.goalTypeTextfieldView.customTextField.text = APPConstants.giftTitle
            self.milestoneTextFieldView.isHidden = true
            self.giftNameTextfieldView.isHidden = false
            self.assignChoresButton.isHidden = false

        case .milestone:
            self.goalTypeTextfieldView.customTextField.text = APPConstants.mileStoneTitle
            self.milestoneTextFieldView.isHidden = false
            self.giftNameTextfieldView.isHidden = true
            self.assignChoresButton.isHidden = true
            
        default:
            break
        }
        // Make sure the currently selected milestone is displayed
        self.updateMilestoneSelection(amount: self.selectedMilestoneAmount)
        
    }
    
    private func updateMilestoneSelection(amount: Int) {

        self.selectedMilestoneAmount = amount

        switch amount {

        case 100:
            self.milestoneTextFieldView.customTextField.text = "100 Coins"
            self.milestoneTextFieldView.showLeftCoinImageView(coinImage: AppImages.hundredCoins)

        case 200:
            self.milestoneTextFieldView.customTextField.text = "200 Coins"
            self.milestoneTextFieldView.showLeftCoinImageView(coinImage: AppImages.twoHundredCoins)

        case 500:
            self.milestoneTextFieldView.customTextField.text = "500 Coins"
            self.milestoneTextFieldView.showLeftCoinImageView(coinImage: AppImages.fiveHundredCoins)

        default:
            self.milestoneTextFieldView.customTextField.text = nil
            self.milestoneTextFieldView.customTextField.rightView = nil
        }
    }
}

//MARK: delegate after assigning chore to get taskid

extension CreateGoalViewController: AssignChoreDelegate {
    
    func didAssignChores(with choreIDs: [String]) {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.selectedTaskIds = choreIDs
    }
}


//MARK: ------------- UI

extension CreateGoalViewController {
    
    private func setCreateGoalScreenUI() {
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.addGoalTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.createGoalButton.setTitle(APPConstants.addGoalTitle, for: .normal)
        self.createGoalButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.createGoalButton.setTitleColor(.white, for: .normal)
        self.createGoalButton.backgroundColor = .pinkPrimaryColor
        self.createGoalButton.layer.cornerRadius = 25
        
        self.goalTypeTextfieldView.customTextField.delegate = self
        self.goalTypeTextfieldView.customTextField.setPlaceholder(text: APPConstants.mileStoneTitle)
        self.goalTypeTextfieldView.placeHolderLabel.text = APPConstants.goalTypeTitle
        self.goalTypeTextfieldView.customTextField.tag = 0
        self.goalTypeTextfieldView.showRightView()
        
        self.milestoneTextFieldView.customTextField.delegate = self
      //  self.milestoneTextFieldView.customTextField.setPlaceholder(text: )
        self.milestoneTextFieldView.placeHolderLabel.text = APPConstants.milestonePlaceholder
        self.milestoneTextFieldView.customTextField.tag = 1
        self.milestoneTextFieldView.showRightView()
        
        self.giftNameTextfieldView.customTextField.delegate = self
        self.giftNameTextfieldView.customTextField.setPlaceholder(text: APPConstants.giftNameTitle)
        self.giftNameTextfieldView.placeHolderLabel.text = APPConstants.giftNamePlaceholder
        self.giftNameTextfieldView.customTextField.tag = 2
        
        self.assignChoresButton.setTitle(APPConstants.assignChores, for: .normal)
        self.assignChoresButton.titleLabel?.font = UIFont(name: Fonts.urbanistExtraBold, size: 14)
        self.assignChoresButton.setTitleColor(.pinkPrimaryColor, for: .normal)
        self.assignChoresButton.backgroundColor = .white
        self.assignChoresButton.layer.cornerRadius = 17.5
        self.assignChoresButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.assignChoresButton.layer.borderWidth = 1
        
        [self.goalTypeTextfieldView.customTextField, self.milestoneTextFieldView.customTextField, self.giftNameTextfieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        
        let goalTypeTap = UITapGestureRecognizer(target: self, action: #selector(showGoalTypeVC))
        self.goalTypeTextfieldView.customTextField.addGestureRecognizer(goalTypeTap)
        self.goalTypeTextfieldView.customTextField.isUserInteractionEnabled = true
        
        let milestoneTap = UITapGestureRecognizer(target: self, action: #selector(showMilestoneVC))
        self.milestoneTextFieldView.customTextField.addGestureRecognizer(milestoneTap)
        self.milestoneTextFieldView.customTextField.isUserInteractionEnabled = true
    }
    
   @objc private func showGoalTypeVC() {
        guard let contentVC = VCManager.openGoalTypeVC() else { return }
        contentVC.didSelectGoalType = { [weak self] type in
           guard let self else { return }

           self.updateGoalTypeUI(type)
           self.floatingPanel?.dismiss(animated: true)
           self.floatingPanel = nil
           
       }
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.4)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    @objc private func showMilestoneVC() {
        guard let contentVC = VCManager.openMilestoneVC() else { return }
        contentVC.didSelectMilestone = { [weak self] amt in
           guard let self else { return }

           self.updateMilestoneSelection(amount: amt)
           self.floatingPanel?.dismiss(animated: true)
           self.floatingPanel = nil
           
       }
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.5)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showAssignChoresVC() {
        guard let contentVC = VCManager.openAssignChoresVC() else { return }
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
    
    
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicator.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.view.sendSubviewToBack(self.activityView)
        self.activityIndicator.stopAnimating()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
          case 0:
            self.goalTypeTextfieldView.hideErrorMessage()
              
          case 1:
            self.milestoneTextFieldView.hideErrorMessage()
            
        case 2:
            self.giftNameTextfieldView.hideError()
        
          default:
              break
          }
    }
    
    private func clearAllErrors() {
        self.goalTypeTextfieldView.hideErrorMessage()
        self.milestoneTextFieldView.hideErrorMessage()
        self.giftNameTextfieldView.hideError()
    }
}

extension CreateGoalViewController: FloatingPanelControllerDelegate, UITextFieldDelegate {
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}

protocol GoalRefreshDelegate: AnyObject {
    func refreshGoals()
}
