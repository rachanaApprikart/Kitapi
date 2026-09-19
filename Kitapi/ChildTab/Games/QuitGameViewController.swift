//
//  QuitGameViewController.swift
//  Kitapi
//
//  Created by Suneel on 07/09/26.
//

import UIKit

class QuitGameViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!

    
    weak var delegate: QuitGameDelegate?


    static var sbIdentifier: String {
        return String(describing: QuitGameViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setQuitGameScreenUI()
    }
    
    
    @IBAction func noAction(_ sender: UIButton) {
        self.delegate?.didTapContinueGame()
    }
    
    @IBAction func yesAction(_ sender: UIButton) {
        self.delegate?.didTapQuitGame()
    }
    
}

extension QuitGameViewController {
    
    private func setQuitGameScreenUI() {
        
        self.headerLabel.text = "Would you like to quit the game?"
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.noButton.setTitle("No", for: .normal)
        self.noButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.noButton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.noButton.backgroundColor = .white
        self.noButton.layer.cornerRadius = 25
        self.noButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.noButton.layer.borderWidth = 1
        
        self.yesButton.setTitle("Yes", for: .normal)
        self.yesButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.yesButton.setTitleColor(.white, for: .normal)
        self.yesButton.backgroundColor = .pinkPrimaryColor
        self.yesButton.layer.cornerRadius = 25
    }
}

protocol QuitGameDelegate: AnyObject {
    func didTapContinueGame()
    func didTapQuitGame()
}
