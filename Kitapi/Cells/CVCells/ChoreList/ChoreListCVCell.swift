//
//  ChoreListCVCell.swift
//  Kitapi
//
//  Created by Suneel on 23/07/26.
// 24/07

import UIKit

class ChoreListCVCell: UICollectionViewCell {
    
    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var choreImageView: UIImageView!
    @IBOutlet weak var choreNameLabel: UILabel!
    
    @IBOutlet weak var rewardCoinsLabel: UILabel!
    @IBOutlet weak var rewardCoinsView: UIView!
    
    @IBOutlet weak var frequencyBGView: UIStackView!
    @IBOutlet weak var recurranceBGView: UIView!
    @IBOutlet weak var recurrenceLabel: UILabel!
    
    @IBOutlet weak var timeBGView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var dateBGView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var choreStatusButton: UIButton!
    
    var onSelectionTapped: (() -> Void)?
    
    static var reUseIdentifier: String {
        return String(describing: ChoreListCVCell.self)
    }
    
    static var nibFile: UINib {
        return UINib(nibName: ChoreListCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setChoreListUI()
        // Initialization code
    }
    
    @IBAction func choreStatusAction(_ sender: UIButton) {
        self.onSelectionTapped?()
    }
    
    func configure(with chore: TaskData, sectionType: ChoreSectionType) {
        
        self.choreNameLabel.text = chore.title
        self.rewardCoinsLabel.text = "\(String(describing: chore.rewardCoins ?? 0))"
        
        let shouldShowSchedule = (sectionType == .upNext)
        
        self.recurrenceLabel.isHidden = !shouldShowSchedule
        self.dateLabel.isHidden = !shouldShowSchedule
        self.timeLabel.isHidden = !shouldShowSchedule
        self.frequencyBGView.isHidden = !shouldShowSchedule
        self.choreStatusButton.isUserInteractionEnabled = shouldShowSchedule
        
        if shouldShowSchedule {
            self.recurrenceLabel.text = chore.recurrence?.rawValue
            self.dateLabel.text = formatDate(chore.dueDate ?? "")
            self.timeLabel.text = formatTime(chore.startTime ?? "")
        }
        
        if let url = URL(string: chore.image?.url ?? "") {
            self.choreImageView.kf.indicatorType = .activity
            self.choreImageView.kf.setImage(with: url)
        }
        
        // status
        switch chore.status {
            
        case .pending, .upcoming:
            
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.setImage(nil, for: .normal)
            self.choreStatusButton.backgroundColor = .white
            
            let radius = min(choreStatusButton.bounds.width, choreStatusButton.bounds.height) / 2 - 2
            
            self.choreStatusButton.createDashedCircle(
                center: CGPoint(x: self.choreStatusButton.bounds.midX, y: self.choreStatusButton.bounds.midY),
                radius: radius,
                color: .buttonStrokeColor,
                strokeLength: 1.5,
                gapLength: 0.5,
                lineWidth: 1.5
            )
        case .completed:
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.backgroundColor = .greenPrimaryColor
            self.choreStatusButton.setImage(AppImages.check, for: .normal)
            
        case .rejected:
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.backgroundColor = .redPrimaryColor
            self.choreStatusButton.setImage(AppImages.close, for: .normal)

        case .overdue:
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.backgroundColor = .orangePrimaryColor
            self.choreStatusButton.setImage(AppImages.exclamation, for: .normal)

        default:
            self.choreStatusButton.removeDashedCircle()
        }
    }
    
    func configureAvailableChores(with chore: TaskData, isSelected: Bool) {
        
        self.choreNameLabel.text = chore.template?.title
        self.onSelectionTapped = nil

        if let url = URL(string: chore.template?.image?.url ?? "") {
            self.choreImageView.kf.indicatorType = .activity
            self.choreImageView.kf.setImage(with: url)
        }
        
        if isSelected {
            self.choreStatusButton.backgroundColor = .greenPrimaryColor
            self.choreStatusButton.setImage(AppImages.check, for: .normal)
          } else {
              self.choreStatusButton.backgroundColor = .white
              self.choreStatusButton.setImage(nil, for: .normal)
          }
        
        self.recurrenceLabel.isHidden = true
        self.dateLabel.isHidden = true
        self.timeLabel.isHidden = true
        self.frequencyBGView.isHidden = true
        self.rewardCoinsView.isHidden = true
        
        self.choreStatusButton.layer.borderWidth = 1
        self.choreStatusButton.layer.borderColor = UIColor.headerLabekColor.cgColor
    }
    
    func configureAssignedTasks(with chore: TaskData) {
        
        self.choreNameLabel.text = chore.taskTemplate?.title
        self.onSelectionTapped = nil

        if let url = URL(string: chore.taskTemplate?.image?.url ?? "") {
            self.choreImageView.kf.indicatorType = .activity
            self.choreImageView.kf.setImage(with: url)
        }

        switch chore.status {
            
        case .pending, .upcoming:
            
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.setImage(nil, for: .normal)
            self.choreStatusButton.backgroundColor = .white
            
            let radius = min(choreStatusButton.bounds.width, choreStatusButton.bounds.height) / 2 - 2
            
            self.choreStatusButton.createDashedCircle(
                center: CGPoint(x: self.choreStatusButton.bounds.midX, y: self.choreStatusButton.bounds.midY),
                radius: radius,
                color: .buttonStrokeColor,
                strokeLength: 1.5,
                gapLength: 0.5,
                lineWidth: 1.5
            )
            
        case .completed:
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.backgroundColor = .greenPrimaryColor
            self.choreStatusButton.setImage(AppImages.check, for: .normal)
            
        case .rejected:
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.backgroundColor = .redPrimaryColor
            self.choreStatusButton.setImage(AppImages.close, for: .normal)

        case .overdue:
            self.choreStatusButton.removeDashedCircle()

            self.choreStatusButton.backgroundColor = .orangePrimaryColor
            self.choreStatusButton.setImage(AppImages.exclamation, for: .normal)

        default:
            self.choreStatusButton.removeDashedCircle()
        }
        
        self.recurrenceLabel.isHidden = true
        self.dateLabel.isHidden = true
        self.timeLabel.isHidden = true
        self.frequencyBGView.isHidden = true
        self.rewardCoinsView.isHidden = true
    }
    
    private func formatDate(_ dateString: String) -> String {
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        
        return outputFormatter.string(from: date)
    }
    
    private func formatTime(_ timeString: String) -> String {
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        guard let date = inputFormatter.date(from: timeString) else {
            return ""
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        return outputFormatter.string(from: date)
    }
}

extension ChoreListCVCell {
    
    private func setChoreListUI() {
        
        self.bgView.layer.borderWidth = 0.5
        self.bgView.layer.borderColor = UIColor.lightGreyColor.cgColor
        self.bgView.layer.cornerRadius = 10
        self.choreStatusButton.removeDashedCircle()
        
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
        
        self.choreStatusButton.layer.cornerRadius = 17.5
        
        self.recurranceBGView.layer.cornerRadius = 5
        self.recurranceBGView.backgroundColor = .gradientColor1
        
        self.dateBGView.layer.cornerRadius = 5
        self.dateBGView.backgroundColor = .gradientColor1
        
        self.timeBGView.layer.cornerRadius = 5
        self.timeBGView.backgroundColor = .gradientColor1
    }
}
