//
//  ChoreAnalyticsCVCell.swift
//  Kitapi
//
//  Created by Suneel on 23/08/26.
// 24/08

import UIKit

class ChoreAnalyticsCVCell: UICollectionViewCell {

    @IBOutlet weak var pendingChoresView: UIView!
    @IBOutlet weak var pendingTitleLabel: UILabel!
    @IBOutlet weak var pendingChoresAnalyticsLabel: UILabel!
    @IBOutlet weak var pendingChoresProgressBarView: AnalyticsProgressBar!
    
    @IBOutlet weak var overdueChoresView: UIView!
    @IBOutlet weak var overdueChoresAnalyticsLabel: UILabel!
    @IBOutlet weak var overdueTitleLabel: UILabel!
    
    @IBOutlet weak var overdueChoresProgressBarView: AnalyticsProgressBar!
    @IBOutlet weak var completedChoresView: UIView!
    @IBOutlet weak var completedChoresAnalyticsLabel: UILabel!
    @IBOutlet weak var completedTitleLabel: UILabel!
    
    @IBOutlet weak var completedChoresProgressBarView: AnalyticsProgressBar!
    @IBOutlet weak var rejectedChoresView: UIView!
    @IBOutlet weak var rejectedChoresAnalyticsLabel: UILabel!
    @IBOutlet weak var rejectedTitleLabel: UILabel!
    
    @IBOutlet weak var rejectedChoresProgressBarView: AnalyticsProgressBar!
    
    static var reUseIdentifier: String {
        return String(describing: ChoreAnalyticsCVCell.self)
    }
    
    static var nibFile: UINib {
        return UINib(nibName: ChoreAnalyticsCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setChoreAnalytivsCVCell()
    }
    
    func configureAnalyticsCell(count: ChoreCount, percentage: ChorePercentage) {
        
        let pendingChoresCount = "\(String(format: "%02d", count.pending ?? 0))/\(count.total)"
        self.pendingChoresAnalyticsLabel.text = pendingChoresCount
        self.pendingChoresProgressBarView.configure(status: .pending, percentage: percentage.pending ?? 0.0)
        
        let overdueChoresCount = "\(String(format: "%02d", count.overdue ?? 0))/\(count.total)"
        self.overdueChoresAnalyticsLabel.text = overdueChoresCount
        self.overdueChoresProgressBarView.configure(status: .overdue, percentage: percentage.overdue ?? 0.0)
        
        let completedChoresCount = "\(String(format: "%02d", count.completed ?? 0))/\(count.total)"
        self.completedChoresAnalyticsLabel.text = completedChoresCount
        self.completedChoresProgressBarView.configure(status: .completed, percentage: percentage.completed ?? 0.0)
        
        let rejectedChoresCount = "\(String(format: "%02d", count.rejected ?? 0))/\(count.total)"
        self.rejectedChoresAnalyticsLabel.text = rejectedChoresCount
        self.rejectedChoresProgressBarView.configure(status: .rejected, percentage: percentage.rejected ?? 0.0)
    }

}

extension ChoreAnalyticsCVCell {
    
    private func setChoreAnalytivsCVCell() {
        
        self.pendingChoresView.layer.borderWidth = 1
        self.pendingChoresView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.pendingChoresView.layer.cornerRadius = 12
        
        self.overdueChoresView.layer.borderWidth = 1
        self.overdueChoresView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.overdueChoresView.layer.cornerRadius = 12
        
        self.rejectedChoresView.layer.borderWidth = 1
        self.rejectedChoresView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.rejectedChoresView.layer.cornerRadius = 12
        
        self.completedChoresView.layer.borderWidth = 1
        self.completedChoresView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.completedChoresView.layer.cornerRadius = 12
    
        self.pendingTitleLabel.textAlignment = .left
        self.pendingTitleLabel.textColor = .textColor
        self.pendingTitleLabel.numberOfLines = 1
        self.pendingTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.pendingTitleLabel.text = "Pending"
        
        self.completedTitleLabel.textAlignment = .left
        self.completedTitleLabel.textColor = .textColor
        self.completedTitleLabel.numberOfLines = 1
        self.completedTitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 12)
        self.completedTitleLabel.text = "Completed"
        
        self.overdueTitleLabel.textAlignment = .left
        self.overdueTitleLabel.textColor = .textColor
        self.overdueTitleLabel.numberOfLines = 1
        self.overdueTitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 12)
        self.overdueTitleLabel.text = "Overdue"
        
        self.rejectedTitleLabel.textAlignment = .left
        self.rejectedTitleLabel.textColor = .textColor
        self.rejectedTitleLabel.numberOfLines = 1
        self.rejectedTitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 12)
        self.rejectedTitleLabel.text = "Rejected"
        
        self.pendingChoresAnalyticsLabel.textAlignment = .right
        self.pendingChoresAnalyticsLabel.textColor = .textColor
        self.pendingChoresAnalyticsLabel.numberOfLines = 1
        self.pendingChoresAnalyticsLabel.font = UIFont(name: Fonts.urbanistBold, size: 16)
        self.pendingChoresAnalyticsLabel.text = ""
        
        self.completedChoresAnalyticsLabel.textAlignment = .left
        self.completedChoresAnalyticsLabel.textColor = .textColor
        self.completedChoresAnalyticsLabel.numberOfLines = 1
        self.completedChoresAnalyticsLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.completedChoresAnalyticsLabel.text = ""

        self.rejectedChoresAnalyticsLabel.textAlignment = .left
        self.rejectedChoresAnalyticsLabel.textColor = .textColor
        self.rejectedChoresAnalyticsLabel.numberOfLines = 1
        self.rejectedChoresAnalyticsLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.rejectedChoresAnalyticsLabel.text = ""
        
        self.overdueChoresAnalyticsLabel.textAlignment = .left
        self.overdueChoresAnalyticsLabel.textColor = .textColor
        self.overdueChoresAnalyticsLabel.numberOfLines = 1
        self.overdueChoresAnalyticsLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.overdueChoresAnalyticsLabel.text = ""
    
     
    }
}

