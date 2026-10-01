//
//  AnalyticsProgressBar.swift
//  Kitapi
//
//  Created by Suneel on 24/08/26.
//

import UIKit

class AnalyticsProgressBar: UIView {
    
    private let trackView = UIView()
    private let progressView = UIView()
    
    private var progressWidthConstraint: NSLayoutConstraint!
    private var currentPercentage: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = bounds.height / 2

        self.progressView.layer.cornerRadius = bounds.height / 2
        self.trackView.layer.cornerRadius = bounds.height / 2
        self.progressWidthConstraint.constant =
            bounds.width * (currentPercentage / 100)
    }
    
    private func setupUI() {
        
        self.clipsToBounds = true
        // Total / background
        self.addSubview(trackView)
        self.trackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.trackView.topAnchor.constraint(equalTo: topAnchor),
            self.trackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Completed portion
        self.trackView.addSubview(progressView)
        
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressWidthConstraint = self.progressView.widthAnchor.constraint(
            equalToConstant: 0
        )
        
        NSLayoutConstraint.activate([
            self.progressView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            self.progressView.topAnchor.constraint(equalTo: trackView.topAnchor),
            self.progressView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            self.progressWidthConstraint
        ])
    }
    
    
    func configure(status: Status, percentage: Double) {
        
        self.trackView.backgroundColor = status.trackColor
        self.progressView.backgroundColor = status.progressColor
        
        self.currentPercentage = CGFloat(min(max(percentage, 0), 100))
        setNeedsLayout()
    }
    
    func configureMilestoneProgress(status: MilestoneAmount, percentage: Double) {
        
        self.trackView.backgroundColor = status.trackColor
        self.progressView.backgroundColor = status.progressColor
        
        self.currentPercentage = CGFloat(min(max(percentage, 0), 100))
        setNeedsLayout()
    }
}


enum Status {
      case pending
      case overdue
      case completed
      case rejected

      var trackColor: UIColor {
          switch self {
              
          case .pending:
              return UIColor.brownPrimaryColor.withAlphaComponent(0.15)

          case .overdue:
              return UIColor.orangePrimaryColor.withAlphaComponent(0.15)

          case .completed:
             return UIColor.greenPrimaryColor.withAlphaComponent(0.15)

          case .rejected:
             return UIColor.redPrimaryColor.withAlphaComponent(0.15)
          }
      }

      var progressColor: UIColor {
          switch self {
          case .pending:
             return UIColor.brownPrimaryColor

          case .overdue:
              return UIColor.orangePrimaryColor

          case .completed:
              return UIColor.greenPrimaryColor

          case .rejected:
              return UIColor.redPrimaryColor
          }
      }
  }

enum MilestoneAmount {
    case hundred
    case twoHundred
    case fiveHundred
    
    var trackColor: UIColor {
        switch self {
            
        case .hundred:
            return UIColor.greenPrimaryColor.withAlphaComponent(0.15)
            
        case .twoHundred:
            return UIColor.purplePrimaryColor.withAlphaComponent(0.15)
            
        case .fiveHundred:
            return UIColor.bluePrimaryColor.withAlphaComponent(0.15)
            
        }
    }
    
    var progressColor: UIColor {
        switch self {
        case .hundred:
            return UIColor.greenPrimaryColor
            
        case .twoHundred:
            return UIColor.purplePrimaryColor
            
        case .fiveHundred:
            return UIColor.greenPrimaryColor
        }
    }
}
