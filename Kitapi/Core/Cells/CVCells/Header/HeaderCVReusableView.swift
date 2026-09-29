//
//  HeaderCVReusableView.swift
//  Kitapi
//
//  Created by Suneel on 15/05/26.
//

import UIKit

class HeaderCVReusableView: UICollectionReusableView {
    
    @IBOutlet weak var leftLineView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var rightLineView: UIView!
    
    static var reUseIdentifier: String {
        return String(describing: HeaderCVReusableView.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: HeaderCVReusableView.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setHeaderCellUI()
    }
}

extension HeaderCVReusableView {
    
    private func setHeaderCellUI() {
        
        self.headerLabel.text = APPConstants.profileTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.headerLabel.textColor = .labelPlaceholderColor
        self.headerLabel.numberOfLines = 1
        
        self.leftLineView.backgroundColor = .lightGreyColor
        self.rightLineView.backgroundColor = .lightGreyColor
    }
}
