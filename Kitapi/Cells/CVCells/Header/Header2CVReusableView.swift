//
//  Header2CVReusableView.swift
//  Kitapi
//
//  Created by Suneel on 25/06/26.
//

import UIKit

class Header2CVReusableView: UICollectionReusableView {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var viewAllButton: UIButton!
    
    var onViewAllChoresTapped: (() -> Void)?

    static var reUseIdentifier: String {
        return String(describing: Header2CVReusableView.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: Header2CVReusableView.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setHeaderCellUI()
    }
    
    func populateHeader(test: String) {
        self.headerLabel.text = test
    }
    
    @IBAction func viewAllAction(_ sender: UIButton) {
        self.onViewAllChoresTapped?()
    }
}

extension Header2CVReusableView {
    
    private func setHeaderCellUI() {
        
        self.headerLabel.textAlignment = .left
        self.headerLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 20)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.viewAllButton.isHidden = true
    
    }
}
