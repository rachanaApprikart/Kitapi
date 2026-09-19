//
//  SelectTemplateImageViewController.swift
//  Kitapi
//
//  Created by Suneel on 29/06/26.
//

import UIKit

class SelectTemplateImageViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var selectedTemplateView: UIView!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var selectedChoreLabel: UILabel!
    
    @IBOutlet weak var chooseIconLabel: UILabel!
    @IBOutlet weak var chooseIconCV: UICollectionView!
    
    @IBOutlet weak var createChoreTemplateButton: UIButton!
    
    let templateIcons: [UIImage] = [AppImages.chore_template_icon_1, AppImages.chore_template_icon_2, AppImages.chore_template_icon_3, AppImages.chore_template_icon_4, AppImages.chore_template_icon_5, AppImages.chore_template_icon_6, AppImages.chore_template_icon_7, AppImages.chore_template_icon_8]
    
    private var selectedIndexPath: IndexPath?
    var selectedChore: String = ""
    
    weak var delegate: CreateTemplateDelegate?
    
    static var sbIdentifier: String {
        return String(describing: SelectTemplateImageViewController.self)
    }
    private let viewModel = SelectTemplateImageViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setChooseIconScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func createChoreTemplateAction(_ sender: UIButton)  {
        
        let text = self.selectedChoreLabel.text ?? ""
        guard let image = self.selectedImage.image else { return  }
        
        let req = CreateChoreTemplateRequest(title: text, image: image)
        
        Task {
            await self.viewModel.createTemplate(request: req)
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.createChoreTemplateButton.isEnabled = !isLoadings
            self.createChoreTemplateButton.alpha = isLoadings ? 0.6 : 1.0
        }
        
        self.viewModel.onCreateTemplateError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewModel.onCreateTemplateSuccess = { [weak self] user in
            guard let self = self else { return }
            
            let data = user.data
            self.delegate?.didCreateTemplate(templateData: data)
        }
    }
}

//MARK: COLLECTION VIEW DELEGATES

extension SelectTemplateImageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.templateIcons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = self.templateIcons[indexPath.item]
        
        guard let pickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoPickerCVCell.reUseIdentifier, for: indexPath) as? PhotoPickerCVCell else {
            return UICollectionViewCell() }
        let isSelected = self.selectedIndexPath == indexPath
        pickerCell.populateTemplateIconCell(items: section, isSelected: isSelected)
        return pickerCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedImage.image = self.templateIcons[indexPath.item]
        
        let previousIndexPath = self.selectedIndexPath
        self.selectedIndexPath = indexPath
        
        var reloadItems: [IndexPath] = [indexPath]
        
        if let previousIndexPath {
            reloadItems.append(previousIndexPath)
        }
        collectionView.reloadItems(at: reloadItems)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 76)
    }
}

extension SelectTemplateImageViewController {
    
    private func setChooseIconScreenUI() {
        self.appBGView.setGradientBackground()
        self.setChooseIconCV()
        
        self.headerLabel.text = APPConstants.selectedChoreTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.selectedChoreLabel.text = self.selectedChore
        self.selectedChoreLabel.textAlignment = .left
        self.selectedChoreLabel.font = UIFont(name: Fonts.urbanistBold, size: 14)
        self.selectedChoreLabel.textColor = .headerLabekColor
        self.selectedChoreLabel.numberOfLines = 1
        
        self.selectedImage.image = self.templateIcons.first
        
        self.chooseIconLabel.text = APPConstants.chooseIconTitle
        self.chooseIconLabel.textAlignment = .left
        self.chooseIconLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 20)
        self.chooseIconLabel.textColor = .headerLabekColor
        self.chooseIconLabel.numberOfLines = 1
        
        self.selectedTemplateView.layer.cornerRadius = 15
        self.selectedTemplateView.layer.borderWidth = 1
        self.selectedTemplateView.layer.borderColor = UIColor.lightGreyColor.cgColor
        
        self.createChoreTemplateButton.setTitle(APPConstants.finishTitle, for: .normal)
        self.createChoreTemplateButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.createChoreTemplateButton.setTitleColor(.white, for: .normal)
        self.createChoreTemplateButton.backgroundColor = .pinkPrimaryColor
        self.createChoreTemplateButton.layer.cornerRadius = 25
    }
    
    private func setChooseIconCV() {
        self.chooseIconCV.delegate = self
        self.chooseIconCV.dataSource = self
        self.chooseIconCV.register(PhotoPickerCVCell.nibFile, forCellWithReuseIdentifier: PhotoPickerCVCell.reUseIdentifier)
    }
    
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicatorView.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.activityIndicatorView.stopAnimating()
        self.view.sendSubviewToBack(self.activityView)
    }
}

protocol CreateTemplateDelegate: AnyObject {
    func didCreateTemplate(templateData: TemplateData)
}
