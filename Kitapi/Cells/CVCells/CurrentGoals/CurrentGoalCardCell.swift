//
//  CurrentGoalCardCell.swift
//  Kitapi
//
//  Created by Suneel on 28/08/26.
//

import UIKit

class CurrentGoalCardCell: UICollectionViewCell {
    
    @IBOutlet weak var goalCardView: UIView!
    @IBOutlet weak var goalTitle: UILabel!
    
    @IBOutlet weak var goalAnalyticsView: UIView!
    @IBOutlet weak var numberOfChoresLabel: UILabel!
    @IBOutlet weak var goalPercentageLabel: UILabel!
    
    @IBOutlet weak var goalsProgressBar: AnalyticsProgressBar!
    
    static var reUseIdentifier: String {
        return String(describing: CurrentGoalCardCell.self)
    }
    
    static var nibFile: UINib {
        return UINib(nibName: CurrentGoalCardCell.reUseIdentifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setGoalCardScreenUI()
        // Initialization code
    }
    
    func populateCurrentGoalCardCell(with goal: GoalData){
        
        self.goalTitle.text = goal.title
        self.numberOfChoresLabel.text = goal.progressDetails?.tasksText
        self.goalPercentageLabel.text = "\(Int(goal.progressPercentage ?? 0))% Completed"
        self.goalsProgressBar.configure(status: .completed, percentage: goal.progressPercentage ?? 0.0)

    }
    
    func populateGoalCardCell(with goal: GoalData){
        
        let totalTask = "\(goal.taskCount ?? 0)"
        let completedTask = "\(goal.completedTaskCount ?? 0)"
        
        self.goalTitle.text = goal.title
        self.numberOfChoresLabel.text = completedTask + "/" + totalTask + " Chores"
        self.goalPercentageLabel.text = "\(Int(goal.progressPercentage ?? 0))% Completed"
        self.goalsProgressBar.configure(status: .completed, percentage: goal.progressPercentage ?? 0.0)

    }

}

extension CurrentGoalCardCell {
    
    private func setGoalCardScreenUI() {
        
        self.goalTitle.textAlignment = .left
        self.goalTitle.textColor = .textColor
        self.goalTitle.numberOfLines = 1
        self.goalTitle.font = UIFont(name: Fonts.urbanistBold, size: 16)
        self.goalTitle.text = ""
        
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
        self.goalAnalyticsView.layer.cornerRadius = 12
        self.goalAnalyticsView.backgroundColor = .lightYellowPrimaryColor

        self.goalCardView.layer.borderWidth = 1
        self.goalCardView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.goalCardView.layer.cornerRadius = 12
    }
}
