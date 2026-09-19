//
//  ChildHeaderView.swift
//  Kitapi
//
//  Created by Suneel on 04/09/26.
//

import Foundation
import UIKit

class ChildHeaderView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var childImageView: UIImageView!
    @IBOutlet weak var childNameLabel: UILabel!
    
    @IBOutlet weak var subheaderView: UIView!
    @IBOutlet weak var dropDownButton: UIButton!
    @IBOutlet weak var modeSwitch: UISwitch!
    @IBOutlet weak var textLabel1: UILabel!
    @IBOutlet weak var textLabel2: UILabel!
    
    @IBOutlet weak var coinsView: UIView!
    @IBOutlet weak var coinsLabel: UILabel!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timerView: UIView!
    
    var onToggleParentMode: ((Bool) -> Void)?
    private var timer: Timer?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            self.startTimer()
            self.refreshChild()
        } else {
            self.stopTimer()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.refreshChild()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadFromNib()
        self.refreshChild()
    }
    
    @IBAction func dropDownAction(_ sender: UIButton) {
        
    }
    
    @IBAction func modeSwitchAction(_ sender: UISwitch) {
        let requestedState = sender.isOn
        
        // Restore the switch to the actual current mode.
        sender.setOn(
            ChildManager.shared.isChildMode,
            animated: false
        )
        self.onToggleParentMode?(requestedState)
    }
    
    
    @objc private func refreshChild() {
        
        DispatchQueue.main.async {
            let child = ChildSessionManager.shared.selectedChild
            
            if let url = URL(string: child?.profilePicture?.url ?? "") {
                self.childImageView.kf.indicatorType = .activity
                self.childImageView.kf.setImage(with: url)
            } else {
                self.childImageView.image = nil
            }
            self.childNameLabel.text = child?.name
            self.coinsLabel.text = (String(describing: child?.coinBalance ?? 0) ) + " Coins"
            // Child Mode → switch represents switching back to Parent Mode.
            self.modeSwitch.isOn = true
        }
    }
    deinit {
        self.stopTimer()
    }

}

// MARK: - TIMER

private extension ChildHeaderView {

    func startTimer() {

        self.stopTimer()

        let remaining =
            ChildSessionManager.shared.remainingSeconds

        if remaining <= 0 {

            self.timerLabel.text = "00:00"

            return
        }

        self.updateTimer()

        let timer = Timer(
            timeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in

            self?.updateTimer()
        }

        self.timer = timer

        RunLoop.main.add(
            timer,
            forMode: .common
        )
    }

    func stopTimer() {

        self.timer?.invalidate()
        self.timer = nil
    }

    func updateTimer() {

        let remaining =
            ChildSessionManager.shared.remainingSeconds

        if remaining <= 0 {

            self.timerLabel.text = "00:00"

            self.stopTimer()

            return
        }

        let minutes = remaining / 60
        let seconds = remaining % 60

        self.timerLabel.text = String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}
    
    


extension ChildHeaderView {
    
    private func loadFromNib() {
        Bundle.main.loadNibNamed("ChildHeaderView", owner: self, options: nil)
        self.subheaderView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subheaderView)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        
        self.coinsView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(coinsView)
        
        self.timerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(timerView)
        
        NSLayoutConstraint.activate([
            self.subheaderView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            self.subheaderView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
            self.subheaderView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
            self.subheaderView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
        ])
        self.subheaderView.setGradientBackgroundForHeader()
        self.subheaderView.layer.cornerRadius = 35
        self.subheaderView.layer.maskedCorners = [
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]
        self.subheaderView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            self.contentView.heightAnchor.constraint(equalToConstant: 70.0),
            self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
            self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
        ])
        self.contentView.layer.cornerRadius = 25
        self.contentView.layer.maskedCorners = [
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]
        self.contentView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            self.coinsView.heightAnchor.constraint(equalToConstant: 25.0),
            self.coinsView.widthAnchor.constraint(equalToConstant: 100.0),
            self.coinsView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20.0),
            self.coinsView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -13.0),
        ])
        self.coinsView.layer.cornerRadius = 12.5
        
        NSLayoutConstraint.activate([
            self.timerView.heightAnchor.constraint(equalToConstant: 25.0),
            self.timerView.widthAnchor.constraint(equalToConstant: 100.0),
            self.timerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20.0),
            self.timerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -13.0),
        ])
        self.timerView.layer.cornerRadius = 10
        self.timerView.backgroundColor = .buttonBackgroundColor
        
        self.childNameLabel.textColor = .textColor
        self.childNameLabel.textAlignment = .left
        self.childNameLabel.numberOfLines = 1
        self.childNameLabel.font = UIFont(name: Fonts.bagelFatOne, size: 16)
        
        self.textLabel1.textColor = .labelPlaceholderColor
        self.textLabel1.textAlignment = .right
        self.textLabel1.numberOfLines = 1
        self.textLabel1.font = UIFont(name: Fonts.urbanistMedium, size: 10)
        self.textLabel1.text = "Switch to"
        
        self.textLabel2.textColor = .headerLabekColor
        self.textLabel2.textAlignment = .right
        self.textLabel2.numberOfLines = 1
        self.textLabel2.font = UIFont(name: Fonts.bagelFatOne, size: 14)
        self.textLabel2.text = "Parent Mode"
        
        self.coinsLabel.textColor = .black
        self.coinsLabel.textAlignment = .right
        self.coinsLabel.numberOfLines = 1
        self.coinsLabel.font = UIFont(name: Fonts.bagelFatOne, size: 12)
        self.coinsLabel.text = "Coins"
        
        self.timerLabel.textColor = .white
        self.timerLabel.textAlignment = .right
        self.timerLabel.numberOfLines = 1
        self.timerLabel.font = UIFont(name: Fonts.bagelFatOne, size: 12)
        self.timerLabel.text = "00:00:00"
        
        self.modeSwitch.onTintColor = .pinkPrimaryColor
        
    }
    
}
//ChildSessionManager
//        │
//        │ persistent expiry
//        ▼
//ChildHeaderView
//        │
//        │ countdown reaches 00:00
//        ▼
//Notification
//        │
//        ▼
//ChildTabViewController
//        │
//        │ show mandatory MPIN
//        ▼
//Re-authentication
//        │
//   ┌────┴────┐
//   │         │
//Wrong      Correct
//   │         │
//   ▼         ▼
//Stay       clearChildModeSession()
//Child         │
//Mode          ▼
//           Parent Mode
