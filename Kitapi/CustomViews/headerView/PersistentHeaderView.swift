//
//  PersistentHeaderView.swift
//  Kitapi
//
//  Created by Suneel on 25/05/26.
//

import UIKit

class PersistentHeaderView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var childImageView: UIImageView!
    @IBOutlet weak var childNameLabel: UILabel!
    
    @IBOutlet weak var modeSwitch: UISwitch!
    @IBOutlet weak var textLabel1: UILabel!
    @IBOutlet weak var textLabel2: UILabel!
    
    var onChildSelectionTapped: (() -> Void)?
    var onToggleChildMode: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.observeChanges()
        self.refresh()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadFromNib()
        self.observeChanges()
        self.refresh()
    }
    
    @IBAction func dropDownAction(_ sender: UIButton) {
        self.onChildSelectionTapped?()
    }
    
    @IBAction func modeSwitchAction(_ sender: UISwitch) {
        // Ask the owner to handle the flow.
        let requestedState = sender.isOn

           sender.setOn(
               ChildManager.shared.isChildMode,
               animated: false
           )

        self.onToggleChildMode?(requestedState)
    }
    
   //existing PersistentHeaderView is observing that notification:
    
    private func observeChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: .childDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: .childModeDidChange,
            object: nil
        )
    }
    
    @objc private func refresh() {
        
        DispatchQueue.main.async {
            let child = ChildManager.shared.selectedChild
            if let url = URL(string: child?.profilePicture?.url ?? "") {
                self.childImageView.kf.indicatorType = .activity
                self.childImageView.kf.setImage(with: url)
            } else {
                self.childImageView.image = nil
            }
            self.childNameLabel.text = child?.name
            self.modeSwitch.isOn = ChildManager.shared.isChildMode
        }
    }
    
    private func loadFromNib() {
        Bundle.main.loadNibNamed("PersistentHeaderView", owner: self, options: nil)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
            self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
            self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
        ])
        
        self.childNameLabel.textColor = .textColor
        self.childNameLabel.textAlignment = .left
        self.childNameLabel.numberOfLines = 1
        self.childNameLabel.font = UIFont(name: Fonts.urbanistExtraBold, size: 16)
        
        self.textLabel1.textColor = .labelPlaceholderColor
        self.textLabel1.textAlignment = .right
        self.textLabel1.numberOfLines = 1
        self.textLabel1.font = UIFont(name: Fonts.urbanistMedium, size: 8)
        self.textLabel1.text = "Switch to"
        
        self.textLabel2.textColor = .headerLabekColor
        self.textLabel2.textAlignment = .right
        self.textLabel2.numberOfLines = 1
        self.textLabel2.font = UIFont(name: Fonts.urbanistSemiBold, size: 13)
        self.textLabel2.text = "Child Mode"
        
        self.modeSwitch.onTintColor = .gradientColor1
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
//ChildManager.shared.isChildMode = true
//NotificationCenter.default.post(name: .childModeDidChange, object: nil)


/// Fired whenever the user taps the switch, regardless of direction.
    /// The switch's visual state is NOT passed here — it's always immediately
    /// reset to reflect `ChildManager.shared.isChildMode` (the source of truth)
    /// before this closure runs. The owner must infer intent from
    /// `ChildManager.shared.isChildMode`:
    ///   - false → user is attempting to enter child mode
    ///   - true  → user is attempting to exit child mode
    /// The switch only ever changes visually via `refresh()`, in response to
    /// `.childModeDidChange` — never set it directly from outside this
