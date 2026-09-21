//
//  ImagePickerViewController.swift
//  Kitapi
//
//  Created by Suneel on 21/09/26.
//

import UIKit

class ImagePickerViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var imagePickerCV: UICollectionView!
    
    let selectionItems: [UIImage] = [AppImages.camera, AppImages.gallery]
    
    static var sbIdentifier: String {
        return String(describing: ImagePickerViewController.self)
    }
    weak var delegate: ImagePickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setImagePickerScreenUI()
    }
    
    deinit {
        print("FloatingPanelController deallocated")
    }
}

//MARK: ---- IMAGE PICEKR ------

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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


//MARK: COLLECTION VIEW DELEGATES


extension ImagePickerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectionItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let pickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoPickerCVCell.reUseIdentifier, for: indexPath) as? PhotoPickerCVCell else {
            return UICollectionViewCell() }
        pickerCell.populateProfileCell(items: self.selectionItems[indexPath.item])
        return pickerCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        indexPath.item == 0 ? self.openCamera() : self.openGallery()
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
            let title = "Choose from gallery/take picture"
            headerView.headerLabel.text = title
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 60)
    }
}



extension ImagePickerViewController {
    
    private func setImagePickerScreenUI() {
        
        self.setImagePickerCV()
        
        self.headerLabel.text = APPConstants.profileTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
    }
    
    private func setImagePickerCV() {
        
        self.imagePickerCV.delegate = self
        self.imagePickerCV.dataSource = self
       
      
        self.imagePickerCV.register(PhotoPickerCVCell.nibFile, forCellWithReuseIdentifier: PhotoPickerCVCell.reUseIdentifier)
        self.imagePickerCV.register(HeaderCVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCVReusableView.reUseIdentifier)
    }
}

protocol ImagePickerDelegate: AnyObject {
    func didSelectProfileImage(imageData: Data, image: UIImage)
}
