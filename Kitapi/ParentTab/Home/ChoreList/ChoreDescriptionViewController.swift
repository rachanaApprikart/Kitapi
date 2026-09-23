//
//  ChoreDescriptionViewController.swift
//  Kitapi
//
//  Created by Suneel on 27/07/26.
//

import UIKit

class ChoreDescriptionViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var choreImageBGView: UIView!
    @IBOutlet weak var choreImageView: UIImageView!
    @IBOutlet weak var rewardCoinsLabel: UILabel!
    @IBOutlet weak var rewardCoinsView: UIView!
    
    @IBOutlet weak var choreNameLabel: UILabel!
    @IBOutlet weak var choreStatusView: UIView!
    @IBOutlet weak var choreStatusImageView: UIImageView!
    
    @IBOutlet weak var recurranceBGView: UIView!
    @IBOutlet weak var recurrenceLabel: UILabel!
    
    @IBOutlet weak var timeBGView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var dateBGView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var descriptionBGView: UIView!
    @IBOutlet weak var descriptionTitleLabel: UILabel!
    @IBOutlet weak var textDescriptionLabel: UILabel!
    
    @IBOutlet weak var audioDescriptionView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    
    @IBOutlet weak var updateChoreStatusView: UIStackView!
    @IBOutlet weak var acceptBGView: UIView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectBGView: UIView!
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var showStatusMesageLabel: UILabel!
    
    private let choresDescriptionViewModel = ChoreDescriptionViewModel()
    weak var delegate: ChoreUpdateDelegate?

    var choreDetail: TaskData?
    var choreId: String = ""

    static var sbIdentifier: String {
        return String(describing: ChoreDescriptionViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setChoreDescriptionScreenUI()
        self.bindViewModel()
        self.fetchChoreDetails()
    }
    
    @IBAction func playAudioAction(_ sender: UIButton) {
    }
    
    
    @IBAction func acceptAction(_ sender: UIButton) {
        self.updateTheChoreStatus(status: .completed, reason: nil)
    }
    
    @IBAction func rejectAction(_ sender: UIButton) {
        self.updateTheChoreStatus(status: .rejected, reason: "Do it properly next time")
    }
    
    private func fetchChoreDetails() {
        guard let childId = ChildManager.shared.selectedChild?.id else { return }

        Task {
            await self.choresDescriptionViewModel.getChoreDetails(choreId: self.choreId, childId: childId)
        }
    }
    
    private func updateTheChoreStatus(status: ChoreStatus, reason: String?) {
        
        guard
            let childId = ChildManager.shared.selectedChild?.id,
            let taskData = choreDetail
        else {
            return
        }
        
        self.choresDescriptionViewModel.taskID = taskData.id
        self.choresDescriptionViewModel.childID = childId
        self.choresDescriptionViewModel.status = status
        self.choresDescriptionViewModel.reason = reason
        
        Task {
            await self.choresDescriptionViewModel.updateChoreStatus()
        }
    }
    
    
    private func bindViewModel() {
        
        self.choresDescriptionViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.choresDescriptionViewModel.onGetChoreDetailsError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.choresDescriptionViewModel.onGetChoreDetailsSuccess = { [weak self] detailsResp in
            guard let self = self else { return }
            self.choreDetail = detailsResp.data.task
            self.configure(details: self.choreDetail, template: detailsResp.data.taskTemplate)
        }
        
        self.choresDescriptionViewModel.onUpdateFailure = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.choresDescriptionViewModel.onUpdateSuccess = { [weak self] updatedChoreList in
            guard let self = self else { return }
            MessageManager.shared.show(message: updatedChoreList.message, type: .success)
            self.delegate?.choreUpdatedSuccessfully()
        }
    }
    
    private func configure(details: TaskData?, template: TemplateData?) {
        
        guard let taskData = details else { return }
        self.choreStatusView.removeDashedCircle()
        
        self.choreNameLabel.text = template?.title ?? ""
        self.textDescriptionLabel.text = taskData.description
        self.rewardCoinsLabel.text = "\(String(describing: taskData.rewardCoins ?? 0))"
        self.recurrenceLabel.text = taskData.recurrence?.rawValue
        self.dateLabel.text = taskData.dueDateFormatted
        
        let startTime = self.formatTime(taskData.startTime)
        let endTime = self.formatTime(taskData.endTime)
        self.timeLabel.text = "\(startTime) - \(endTime)"
        
        if let url = URL(string: template?.image?.url ?? "") {
            self.choreImageView.kf.indicatorType = .activity
            self.choreImageView.kf.setImage(with: url)
        }
        
        // status
        switch taskData.status {
            
        case .pending, .upcoming:
            self.showUpdateChoreStatusView()
            
            self.choreStatusImageView.image = nil
            self.choreStatusView.backgroundColor = .white
            
            let radius = min(choreStatusView.bounds.width, choreStatusView.bounds.height) / 2 - 2
            self.choreStatusView.createDashedCircle(
                center: CGPoint(x: self.choreStatusView.bounds.midX, y: self.choreStatusView.bounds.midY),
                radius: radius,
                color: .buttonStrokeColor,
                strokeLength: 1.5,
                gapLength: 0.5,
                lineWidth: 1.5
            )
            
        case .completed:
            self.displayStatusMesageLabel()
            
            self.showStatusMesageLabel.text = APPConstants.choreApprovedMessage
            self.showStatusMesageLabel.textColor = .greenPrimaryColor
            self.choreStatusView.backgroundColor = .greenPrimaryColor
            self.choreStatusImageView.image = AppImages.check
            
        case .rejected:
            self.displayStatusMesageLabel()
            
            self.choreStatusView.backgroundColor = .redPrimaryColor
            self.choreStatusImageView.image = AppImages.close
            self.showStatusMesageLabel.text = APPConstants.choreRejectedMessage
            self.showStatusMesageLabel.textColor = .redPrimaryColor
            
        case .overdue:
            self.displayStatusMesageLabel()
            
            self.choreStatusView.backgroundColor = .orangePrimaryColor
            self.choreStatusImageView.image = AppImages.exclamation
            self.showStatusMesageLabel.text = APPConstants.choreOverdueMessage
            self.showStatusMesageLabel.textColor = .orangePrimaryColor
            
        default:
            self.choreStatusView.removeDashedCircle()
        }
    }
    
    
    private func formatDate(_ dateString: String?) -> String {
        
        guard let dateStrings = dateString else { return "" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateStrings) else {
            return ""
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        
        return outputFormatter.string(from: date)
    }
    
    private func formatTime(_ timeString: String?) -> String {
        
        guard let timeStrings = timeString else { return "" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        guard let date = inputFormatter.date(from: timeStrings) else {
            return ""
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        return outputFormatter.string(from: date)
    }
}

//28-07

extension ChoreDescriptionViewController {
    
    private func setChoreDescriptionScreenUI() {
        self.hideActivityIndicator()
        self.choreImageBGView.layer.cornerRadius = 20
        self.choreImageBGView.backgroundColor = .gradientColor2
        
        self.headerLabel.text = APPConstants.choreDetailsTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.rewardCoinsView.layer.cornerRadius = 9
        self.rewardCoinsView.backgroundColor = .goldenPrimaryColor
        
        self.choreNameLabel.textAlignment = .left
        self.choreNameLabel.textColor = .textColor
        self.choreNameLabel.numberOfLines = 1
        self.choreNameLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        
        self.rewardCoinsLabel.textAlignment = .center
        self.rewardCoinsLabel.textColor = .textColor
        self.rewardCoinsLabel.numberOfLines = 1
        self.rewardCoinsLabel.font = UIFont(name: Fonts.urbanistBold, size: 10)

        self.recurrenceLabel.textAlignment = .left
        self.recurrenceLabel.textColor = .textColor
        self.recurrenceLabel.numberOfLines = 1
        self.recurrenceLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 10)
        
        self.dateLabel.textAlignment = .left
        self.dateLabel.textColor = .textColor
        self.dateLabel.numberOfLines = 1
        self.dateLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 10)
        
        self.timeLabel.textAlignment = .left
        self.timeLabel.textColor = .textColor
        self.timeLabel.numberOfLines = 1
        self.timeLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 10)
        
        self.choreStatusView.layer.cornerRadius = 17.5
        
        self.recurranceBGView.layer.cornerRadius = 5
        self.recurranceBGView.backgroundColor = .gradientColor1
        
        self.dateBGView.layer.cornerRadius = 5
        self.dateBGView.backgroundColor = .gradientColor1
        
        self.timeBGView.layer.cornerRadius = 5
        self.timeBGView.backgroundColor = .gradientColor1
        
        //29-07
        
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

        self.descriptionTitleLabel.text = APPConstants.descriptionTitle
        self.descriptionTitleLabel.textAlignment = .left
        self.descriptionTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.descriptionTitleLabel.textColor = .labelPlaceholderColor
        self.descriptionTitleLabel.numberOfLines = 1
        
        self.textDescriptionLabel.text = ""
        self.textDescriptionLabel.textAlignment = .left
        self.textDescriptionLabel.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.textDescriptionLabel.textColor = .textColor
        self.textDescriptionLabel.numberOfLines = 2
        
        self.descriptionBGView.layer.borderWidth = 0.3
        self.descriptionBGView.layer.borderColor = UIColor.lightGreyColor.cgColor
        self.descriptionBGView.layer.cornerRadius = 10

        self.showStatusMesageLabel.text = ""
        self.showStatusMesageLabel.textAlignment = .center
        self.showStatusMesageLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.showStatusMesageLabel.numberOfLines = 1
        
        self.playButton.layer.cornerRadius = 15
    }
    
    private func showUpdateChoreStatusView(){
        
        self.updateChoreStatusView.isHidden = false
        self.view.bringSubviewToFront(self.updateChoreStatusView)
        
        self.showStatusMesageLabel.isHidden = true
        self.view.sendSubviewToBack(self.showStatusMesageLabel)
    }
    
    private func displayStatusMesageLabel(){
        
        self.showStatusMesageLabel.isHidden = false
        self.view.bringSubviewToFront(self.showStatusMesageLabel)
        
        self.updateChoreStatusView.isHidden = true
        self.view.sendSubviewToBack(self.updateChoreStatusView)
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
