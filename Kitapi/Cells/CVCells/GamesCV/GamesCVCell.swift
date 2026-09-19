//
//  GamesCVCell.swift
//  Kitapi
//
//  Created by Suneel on 06/09/26.
//

import UIKit

class GamesCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var gameImageView: UIImageView!
    @IBOutlet weak var gameNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var onPlayButtonTapped: (() -> Void)?

    static var reUseIdentifier: String {
        return String(describing: GamesCVCell.self)
    }
    
    
    static var nibFile: UINib {
        return UINib(nibName: GamesCVCell.reUseIdentifier, bundle: nil)
    }
    
    @IBAction func playAction(_ sender: UIButton) {
        self.onPlayButtonTapped?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setGamesCVCellUI()
    }

    func populateGameCell(games: Game, color: UIColor) {
        self.gameNameLabel.text = games.name
        self.bgView.backgroundColor = color
        self.playButton.setTitleColor(color, for: .normal)
        
        
        if let url = URL(string: games.image.first?.url ?? "") {
            self.gameImageView.kf.indicatorType = .activity
            self.gameImageView.kf.setImage(with: url)
        } else {
            self.gameImageView.image = nil
        }

    }
}


extension GamesCVCell {
    
    private func setGamesCVCellUI() {
        
        self.bgView.layer.cornerRadius = 12
        self.bgView.backgroundColor = nil

        self.gameNameLabel.textAlignment = .center
        self.gameNameLabel.numberOfLines = 1
        self.gameNameLabel.font = UIFont(name: Fonts.bagelFatOne, size: 20)
        self.gameNameLabel.text = ""
        self.gameNameLabel.textColor = .white
        
        self.playButton.setTitle("Play", for: .normal)
        self.playButton.titleLabel?.font = UIFont(name: Fonts.balsamiqSansBold, size: 14)
        self.playButton.layer.cornerRadius = 20
        self.playButton.setTitleColor(.white, for: .normal)
        self.playButton.backgroundColor = .white
        self.playButton.setTitleColor(nil, for: .normal)

    }
}
