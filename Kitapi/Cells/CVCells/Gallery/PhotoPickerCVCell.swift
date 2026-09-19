//
//  PhotoPickerCVCell.swift
//  Kitapi
//
//  Created by Suneel on 16/05/26.
//

import UIKit

class PhotoPickerCVCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var photoPickerImageView: UIImageView!
    
    @IBOutlet weak var imageWidthContraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightContraint: NSLayoutConstraint!
    
    static var reUseIdentifier: String {
        return String(describing: PhotoPickerCVCell.self)
    }
        
    static var nibFile: UINib {
        return UINib(nibName: PhotoPickerCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    func populateProfileCell(items: UIImage) {
        self.photoPickerImageView.image = items
        self.bgView.backgroundColor = .gradientColor1
        self.bgView.layer.cornerRadius = 36
        
        self.imageWidthContraint.constant = 32
        self.imageHeightContraint.constant = 32

    }
    
    
    func populateTemplateIconCell(items: UIImage, isSelected: Bool = false) {
        self.photoPickerImageView.image = items
        self.imageWidthContraint.constant = 60
        self.imageHeightContraint.constant = 60

        self.bgView.backgroundColor = .white
        self.bgView.layer.cornerRadius = 10
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor =  isSelected ? UIColor.pinkPrimaryColor.cgColor : UIColor.lightGreyColor.cgColor
    }
}
