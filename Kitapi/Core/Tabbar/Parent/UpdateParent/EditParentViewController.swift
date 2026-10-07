//
//  EditParentViewController.swift
//  Kitapi
//
//  Created by Suneel on 03/10/26.
//

import UIKit
import Kingfisher
import FloatingPanel


class EditParentViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var editParentAccLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var editProfilePhotoView: UIView!
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var editProfilePhotoBtn: UIButton!
    
    @IBOutlet weak var nameTextFieldView: CustomTextField!
    @IBOutlet weak var emailTextFieldView: CustomTextField!
    @IBOutlet weak var genderTextFieldView: CustomTextField!
    
    @IBOutlet weak var phoneNumberPlaceholder: UILabel!
    @IBOutlet weak var phoneNumberTextFieldView: CustomTextField!
    
    @IBOutlet weak var countryCodeButton: UIButton!
    @IBOutlet weak var countryCodeLabel: UILabel!
    
    @IBOutlet weak var editProfileButton: UIButton!
    fileprivate let genderDropDown = DropDown()
    
    private let viewModel = EditParentViewModel()
    
    private var floatingPanel: FloatingPanelController?
    
    static var sbIdentifier: String {
        return String(describing: EditParentViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setEditParentScreenUI()
        self.setEditParentProfileScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func editProfileImageAction(_ sender: UIButton) {
        self.openImagePickerVC()
    }
    
    
    @IBAction func editProfileAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.viewModel.name = self.nameTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.phone = self.phoneNumberTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.gender = self.genderTextFieldView.customTextField.text ?? ""
        
        Task {
            await self.viewModel.register()
        }
    }
    
    private func setEditParentProfileScreenUI() {
        
        guard let parent = AppUserDefaults.customerDetails else { return }
        self.nameTextFieldView.customTextField.text = parent.name
        self.emailTextFieldView.customTextField.text = parent.email
        self.genderTextFieldView.customTextField.text = parent.gender
        self.phoneNumberTextFieldView.customTextField.text = parent.phone ?? ""
        
        if let url = URL(string: parent.image?.url ?? "") {
            self.profilePhotoImageView.kf.setImage(with: url) { [weak self] result in
                
                switch result {
                    
                case .success(let value):
                    self?.viewModel.profilePicture = value.image
                    
                case .failure(let error):
                    print("Failed to load profile image:", error)
                }
            }
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.onValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
                
            case .nameField:
                self.nameTextFieldView.showError(message: error.message)
                
            case .genderField:
                self.genderTextFieldView.showError(message: error.message)
                
            default:
                break
            }
        }
        
        self.viewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.editProfileButton.isEnabled = !isLoadings
            self.editProfileButton.alpha = isLoadings ? 0.6 : 1.0
        }
        
        self.viewModel.onUpdateError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewModel.onUpdateSuccess = { [weak self] verifiedParent in
            guard let self = self else { return }
            AppUserDefaults.customerDetails = verifiedParent.user
            MessageManager.shared.show(message: verifiedParent.message, type: .success)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func clearAllErrors() {
        self.nameTextFieldView.hideErrorMessage()
        self.phoneNumberTextFieldView.hideErrorMessage()
        self.genderTextFieldView.hideErrorMessage()
    }
}

//MARK: IMAGE PICKER DDELEGATE

extension EditParentViewController: ImagePickerDelegate {
    
    func didSelectProfileImage(imageData: Data, image: UIImage) {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.profilePhotoImageView.image = UIImage(data: imageData)
        self.viewModel.profilePicture = image
    }
}

extension EditParentViewController {
    
    private func setEditParentScreenUI() {
        
        self.appBGView.setGradientBackground()
        self.setupGenderDropdown()
        
        self.editParentAccLabel.text = APPConstants.editParentAcc
        self.editParentAccLabel.textAlignment = .center
        self.editParentAccLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.editParentAccLabel.textColor = .headerLabekColor
        self.editParentAccLabel.numberOfLines = 1
        
        self.editProfilePhotoView.layer.cornerRadius = 45
        self.editProfilePhotoView.layer.borderWidth = 1
        self.editProfilePhotoView.layer.borderColor = UIColor.borderColor.cgColor
        
        self.profilePhotoImageView.layer.cornerRadius = 45
        
        self.editProfileButton.setTitle(APPConstants.editParentAcc, for: .normal)
        self.editProfileButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.editProfileButton.setTitleColor(.white, for: .normal)
        self.editProfileButton.backgroundColor = .pinkPrimaryColor
        self.editProfileButton.layer.cornerRadius = 25
        
        self.nameTextFieldView.customTextField.delegate = self
        self.nameTextFieldView.placeHolderLabel.text = APPConstants.fullNameTitle
        self.nameTextFieldView.customTextField.tag = 0
        
        self.genderTextFieldView.customTextField.delegate = self
        self.genderTextFieldView.placeHolderLabel.text = APPConstants.genderTitle
        self.genderTextFieldView.customTextField.tag = 1
        self.genderTextFieldView.showRightView()
        
        self.emailTextFieldView.customTextField.delegate = self
        self.emailTextFieldView.placeHolderLabel.text = APPConstants.emailTitle
        self.emailTextFieldView.customTextField.isEnabled = false
        
        self.phoneNumberTextFieldView.customTextField.delegate = self
        self.phoneNumberTextFieldView.customTextField.setPlaceholder(text: APPConstants.phoneNumberPlaceholder)
        self.phoneNumberTextFieldView.errorLabel.textAlignment = .right
        self.phoneNumberTextFieldView.customTextField.tag = 2
        
        self.phoneNumberPlaceholder.text = APPConstants.phoneNumberTitle
        self.phoneNumberPlaceholder.textAlignment = .left
        self.phoneNumberPlaceholder.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        self.phoneNumberPlaceholder.textColor = .labelPlaceholderColor
        self.phoneNumberPlaceholder.numberOfLines = 1
        
        self.countryCodeButton.layer.cornerRadius = 15
        self.countryCodeButton.layer.borderWidth = 0.5
        self.countryCodeButton.layer.borderColor = UIColor.borderColor.cgColor
        
        self.countryCodeLabel.text = "+91"
        self.countryCodeLabel.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.countryCodeLabel.textColor = .textColor
        self.countryCodeLabel.textAlignment = .left
        self.countryCodeLabel.numberOfLines = 1
        
        [self.nameTextFieldView.customTextField, self.phoneNumberTextFieldView.customTextField, self.genderTextFieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(genderFieldTapped))
        self.genderTextFieldView.customTextField.addGestureRecognizer(tap)
        self.genderTextFieldView.customTextField.isUserInteractionEnabled = true
    }
    
      @objc private func textFieldDidChange(_ textField: UITextField) {
          
          switch textField.tag {
              
            case 0:
              self.nameTextFieldView.hideError()
                
            case 1:
              self.genderTextFieldView.hideError()
                
            case 2:
              self.phoneNumberTextFieldView.hideError()
                
            default:
                break
            }
      }
    
    private func setupGenderDropdown() {
        
        self.genderDropDown.anchorView = genderTextFieldView.customTextField
        self.genderDropDown.dataSource = ["Male", "Female"]
        self.genderDropDown.bottomOffset = CGPoint(
            x: 0,
            y: genderTextFieldView.customTextField.bounds.height
        )
        
        self.genderDropDown.selectionAction = { [weak self] index, item in
            self?.genderTextFieldView.customTextField.text = item
            self?.viewModel.gender = item.lowercased()
            
            // Hide error if any
            self?.genderTextFieldView.hideError()
        }
    }
    
    @objc func genderFieldTapped() {
        self.view.endEditing(true)
        self.genderDropDown.show()
    }
    
    private func openImagePickerVC() {
        guard let contentVC = VCManager.openImagePickerVC() else { return }
        contentVC.delegate = self
        self.presentFloatingPanel(with: contentVC, layout: FloatingPanelCustomLayout(state: .half, inset: 0.4)
        )
    }
    
    private func presentFloatingPanel(with contentVC: UIViewController, layout: FloatingPanelLayout)
    {

        guard floatingPanel == nil else { return }
        
        let fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        
        // Appearance
        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false
        
        // Layout
        fpc.layout = layout
        
        // Dismiss interactions
        fpc.isRemovalInteractionEnabled = true
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        
        self.floatingPanel = fpc
        self.present(fpc, animated: true)
    }
    
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicator.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.view.sendSubviewToBack(self.activityView)
        self.activityIndicator.stopAnimating()
    }
}

extension EditParentViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField == self.nameTextFieldView.customTextField)  {
          return string.allowOnlyCharcters()
        }
        else if textField == self.phoneNumberTextFieldView.customTextField {
            return string.checkForNumberCount(charsLimit: 10, textField: textField, range: range)
        }
        return true
    }
}

extension EditParentViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
}
