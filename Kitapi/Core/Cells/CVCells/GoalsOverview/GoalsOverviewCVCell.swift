//
//  GoalsOverviewCVCell.swift
//  Kitapi
//
//  Created by Suneel on 24/08/26.
//

import UIKit

class GoalsOverviewCVCell: UICollectionViewCell {
    
    @IBOutlet weak var goalsOverView: UIView!
    
    @IBOutlet weak var completedGoalsView: UIView!
    @IBOutlet weak var completedGoalsAnalyticsLabel: UILabel!
    @IBOutlet weak var completedGoalsTitleLabel: UILabel!
    
    @IBOutlet weak var pendingGoalsView: UIView!
    @IBOutlet weak var pendingGoalsAnalyticsLabel: UILabel!
    @IBOutlet weak var pendingGoalsTitleLabel: UILabel!
    
    @IBOutlet weak var currentGoalsOverview: UIView!
    @IBOutlet weak var currentGoalsCount: UIPageControl!
    @IBOutlet weak var currentGoalsCV: UICollectionView!
    @IBOutlet weak var currentGoalsLabel: UILabel!
    
    private var currentGoals: [GoalData] = []

    
    static var reUseIdentifier: String {
        return String(describing: GoalsOverviewCVCell.self)
    }
    
    static var nibFile: UINib {
        return UINib(nibName: GoalsOverviewCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setGoalsOverviewCVCell()
        // Initialization code
    }
    
    func configureGoalsAnalyticsCell(count: GoalCount, goalData: [GoalData]) {
        
        let pendingGoalsCount = "\(String(format: "%02d", count.pending ?? 0))"
        self.pendingGoalsAnalyticsLabel.text = pendingGoalsCount
        
        let completedGoalsCount = "\(String(format: "%02d", count.completed ?? 0))"
        self.completedGoalsAnalyticsLabel.text = completedGoalsCount
        
        // Only gift goals belong to Current Goals
        self.currentGoals = goalData.filter {
            $0.goalType == .gift
        }
        
        self.currentGoalsCount.numberOfPages = self.currentGoals.count
        self.currentGoalsCount.currentPage = 0
        self.currentGoalsCV.reloadData()
    }
}

//MARK: COLLECTION VIEW DELEGATES

extension GoalsOverviewCVCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentGoals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let goalCell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrentGoalCardCell.reUseIdentifier, for: indexPath) as? CurrentGoalCardCell else {
            return UICollectionViewCell() }
        
        let goal = self.currentGoals[indexPath.item]
        goalCell.populateCurrentGoalCardCell(with: goal)
        return goalCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard scrollView == self.currentGoalsCV else {
            return
        }
        let pageWidth = scrollView.bounds.width
        
        guard pageWidth > 0 else {
            return
        }
        
        let page = Int(
            round(scrollView.contentOffset.x / pageWidth)
        )
        
        self.currentGoalsCount.currentPage = page
    }
    
  
}


extension GoalsOverviewCVCell {
    
    private func setGoalsOverviewCVCell() {
        self.setupCurrentGoalsCollectionView()

        self.goalsOverView.layer.borderWidth = 1
        self.goalsOverView.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.goalsOverView.layer.cornerRadius = 12
        
        self.currentGoalsOverview.layer.borderWidth = 1
        self.currentGoalsOverview.layer.borderColor = UIColor.buttonBorderColor.cgColor
        self.currentGoalsOverview.layer.cornerRadius = 12
        
        self.completedGoalsView.backgroundColor = .greenPrimaryColor.withAlphaComponent(0.15)
        self.pendingGoalsView.backgroundColor = .lightYellowPrimaryColor
        self.completedGoalsView.layer.cornerRadius = 12
        self.pendingGoalsView.layer.cornerRadius = 12

        self.completedGoalsTitleLabel.textAlignment = .left
        self.completedGoalsTitleLabel.textColor = .textColor
        self.completedGoalsTitleLabel.numberOfLines = 1
        self.completedGoalsTitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 14)
        self.completedGoalsTitleLabel.text = "Completed"
        
        self.currentGoalsLabel.textAlignment = .left
        self.currentGoalsLabel.textColor = .buttonTitleColor
        self.currentGoalsLabel.numberOfLines = 1
        self.currentGoalsLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 14)
        self.currentGoalsLabel.text = "Current Goal"
        
        self.pendingGoalsTitleLabel.textAlignment = .left
        self.pendingGoalsTitleLabel.textColor = .textColor
        self.pendingGoalsTitleLabel.numberOfLines = 1
        self.pendingGoalsTitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 14)
        self.pendingGoalsTitleLabel.text = "Pending"
        
        self.completedGoalsAnalyticsLabel.textAlignment = .right
        self.completedGoalsAnalyticsLabel.textColor = .textColor
        self.completedGoalsAnalyticsLabel.numberOfLines = 1
        self.completedGoalsAnalyticsLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.completedGoalsAnalyticsLabel.text = ""
        
        self.pendingGoalsAnalyticsLabel.textAlignment = .right
        self.pendingGoalsAnalyticsLabel.textColor = .textColor
        self.pendingGoalsAnalyticsLabel.numberOfLines = 1
        self.pendingGoalsAnalyticsLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.pendingGoalsAnalyticsLabel.text = ""
        
        self.currentGoalsCount.hidesForSinglePage = true
        self.currentGoalsCount.currentPage = 0
        self.currentGoalsCount.currentPageIndicatorTintColor = .pinkPrimaryColor
        self.currentGoalsCount.pageIndicatorTintColor = UIColor.pinkPrimaryColor.withAlphaComponent(0.25)
        self.currentGoalsCount.isUserInteractionEnabled = false
    }
    
    
    func setupCurrentGoalsCollectionView() {

        self.currentGoalsCV.backgroundColor = .clear
        self.currentGoalsCV.showsHorizontalScrollIndicator = false
        self.currentGoalsCV.isPagingEnabled = false

        self.currentGoalsCV.delegate = self
        self.currentGoalsCV.dataSource = self
        self.currentGoalsCV.register(CurrentGoalCardCell.nibFile, forCellWithReuseIdentifier: CurrentGoalCardCell.reUseIdentifier)
    
    }
}
