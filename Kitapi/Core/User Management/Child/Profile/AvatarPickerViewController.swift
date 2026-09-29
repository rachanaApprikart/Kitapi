//
//  AvatarPickerViewController.swift
//  Kitapi
//
//  Created by Suneel on 15/05/26.
//

import UIKit

class AvatarPickerViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var avatarSelectionCV: UICollectionView!
    
    let selectionItems: [UIImage] = [AppImages.camera, AppImages.gallery]
    let boysImages: [UIImage] = [AppImages.boy_avatar_1, AppImages.boy_avatar_2, AppImages.boy_avatar_3, AppImages.boy_avatar_4]
    let girlsImages: [UIImage] = [AppImages.girl_avatar_1, AppImages.girl_avatar_2, AppImages.girl_avatar_3, AppImages.girl_avatar_4]
    
   lazy var avatarDetails: [AvatarSection] = [
        
        AvatarSection(
            type: .pickerOptions,
            title: "Choose from gallery/take picture",
            items: selectionItems
        ),
        
        AvatarSection(
            type: .boys,
            title: "Boys avatar",
            items: boysImages
        ),
        
        AvatarSection(
            type: .girls,
            title: "Girls avatar",
            items: girlsImages
        )
    ]
    private var selectedIndexPath: IndexPath?
    weak var delegate: AvatarPickerDelegate?
    
    static var sbIdentifier: String {
        return String(describing: AvatarPickerViewController.self)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setProfileScreenUI()
      
    }
    
    deinit {
        print("FloatingPanelController deallocated")
    }
}

//MARK: ---- IMAGE PICEKR ------

extension AvatarPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private func openCamera() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            MessageManager.shared.show(message: "Camera not available")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func openGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        guard let image = info[.originalImage] as? UIImage else {
            MessageManager.shared.show(message: "No image found")
            return
        }
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            
            if data.count <= (4000000) {
                self.delegate?.didSelectProfileImage(imageData: data, image: image)
            } else {
                MessageManager.shared.show(message: "Image size cannot exceed 5MB")
            }
        }

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


//MARK: COLLECTION VIEW DDELEGATES

extension AvatarPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.avatarDetails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.avatarDetails[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = self.avatarDetails[indexPath.section]
                
        if section.type == .pickerOptions {
            guard let pickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoPickerCVCell.reUseIdentifier, for: indexPath) as? PhotoPickerCVCell else {
                return UICollectionViewCell() }
            pickerCell.populateProfileCell(items: section.items[indexPath.item])
            return pickerCell
        } else {
            guard let avatarCell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarCVCell.reUseIdentifier, for: indexPath) as? AvatarCVCell else {
                return UICollectionViewCell() }
            //Tests both [1,2], [1,3]
            let isSelected = selectedIndexPath == indexPath

            avatarCell.populateAvatarCell(items: section.items[indexPath.item], isSelected: isSelected)
            return avatarCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = avatarDetails[indexPath.section]
        
        switch section.type {
            
        case .pickerOptions:
            
            indexPath.item == 0 ? self.openCamera() : self.openGallery()
                        
        case .boys, .girls:
            let selectedAvatar = section.items[indexPath.item]
            
            //Suppose [1,3] is selected, [1,2] is previous indexpath
            let previousIndexPath = selectedIndexPath
            selectedIndexPath = indexPath  // (1,3) is selected
            
            var reloadItems: [IndexPath] = [indexPath] //[1,3] -> currently selected
            
            if let previousIndexPath {
                reloadItems.append(previousIndexPath) //append previously selected [[1,2], [1,3]]
            }
            collectionView.reloadItems(at: reloadItems)
            
            if let imageData = selectedAvatar.pngData() {
                self.delegate?.didSelectProfileImage(imageData: imageData, image: selectedAvatar)
            } else {
                MessageManager.shared.show(message: "Image cannot be converted")
            }
            
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 72, height: 72)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderCVReusableView.reUseIdentifier, for: indexPath) as? HeaderCVReusableView else {
                return UICollectionReusableView()
            }
            let title = self.avatarDetails[indexPath.section].title
            headerView.headerLabel.text = title
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 60)
    }
}

extension AvatarPickerViewController {
    
    private func setProfileScreenUI() {
        
        self.setAvatarCV()
        
        self.headerLabel.text = APPConstants.profileTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
    }
    
    private func setAvatarCV() {
        
        self.avatarSelectionCV.delegate = self
        self.avatarSelectionCV.dataSource = self
       
        self.avatarSelectionCV.register(AvatarCVCell.nibFile, forCellWithReuseIdentifier: AvatarCVCell.reUseIdentifier)
        self.avatarSelectionCV.register(PhotoPickerCVCell.nibFile, forCellWithReuseIdentifier: PhotoPickerCVCell.reUseIdentifier)
        self.avatarSelectionCV.register(HeaderCVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCVReusableView.reUseIdentifier)
    }
}

protocol AvatarPickerDelegate: AnyObject {
    func didSelectProfileImage(imageData: Data, image: UIImage)
}
