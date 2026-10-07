//
//  ChildProfileViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/05/26.
//

import UIKit
import FloatingPanel
import Kingfisher

class ChildProfileViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var addProfileView: UIView!
    @IBOutlet weak var addProfileImageView: UIImageView!
    @IBOutlet weak var editProfileButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nameTextFieldView: CustomTextField!
    @IBOutlet weak var dobTextFieldView: CustomTextField!
    @IBOutlet weak var genderTextFieldView: CustomTextField!
    
    @IBOutlet weak var createChildProfileButton: UIButton!
    
    fileprivate let genderDropDown = DropDown()

    private var floatingPanel: FloatingPanelController?
    private let viewModel = ChildProfileViewModel()
    private let formatter = DateFormatter()

    var selectedChild: Child?
    var IS_COMING_FROM_PROFILE_SCREEN:Bool = false
    
    static var sbIdentifier: String {
        return String(describing: ChildProfileViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setCreateChildProfileScreenUI()
        self.setUpdateChildScreenUI()
        self.bindViewModel()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func editProffileAction(_ sender: UIButton) {
        self.openAvatarPickerVC()
    }
    
    private func setUpdateChildScreenUI() {

        guard let childDetails = self.selectedChild else {
            return
        }

        self.nameTextFieldView.customTextField.text = childDetails.name
        self.genderTextFieldView.customTextField.text = childDetails.gender

        let dateString = self.formatDate(childDetails.dateOfBirth ?? "")
        self.dobTextFieldView.customTextField.text = dateString

        if let imageURL = childDetails.profilePicture?.url,
           let url = URL(string: imageURL) {

            self.addProfileImageView.kf.setImage(with: url) { [weak self] result in

                switch result {

                case .success(let value):
                    self?.viewModel.profilePicture = value.image

                case .failure(let error):
                    print("Failed to load profile image:", error)
                }
            }
        }
    }
   
    
    @IBAction func createChildProfileAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.viewModel.childName = self.nameTextFieldView.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.childGender = self.genderTextFieldView.customTextField.text?.lowercased() ?? ""
        self.viewModel.childDob = self.dobTextFieldView.customTextField.text ?? ""
        
        if let childId = self.selectedChild?.id {
            self.updateChildProfile(childId: childId)
        } else {
            self.createChildProfile()
        }
        
    }
    
    
    private func bindViewModel() {
        
        self.viewModel.onValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
            case .nameField:
                self.nameTextFieldView.showError(message: error.message)
          
            case .dobField:
                self.dobTextFieldView.showError(message: error.message)
                
            case .genderField:
                self.genderTextFieldView.showError(message: error.message)
                
            default:
                break
            }
        }
        
        self.viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }
            isLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
            
            self.createChildProfileButton.isEnabled = !isLoading
            self.createChildProfileButton.alpha = isLoading ? 0.6 : 1.0
        }
        
        self.viewModel.onCreateChildProfileError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
      
        self.viewModel.onCreateChildProfileSuccess = { [weak self] user in
            guard let self = self else { return }
            MessageManager.shared.show(message: user.message, type: .success)
            self.handleRegistrationSuccess()
        }
        
        self.viewModel.onUpdateChildProfileError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
      
        self.viewModel.onUpdateChildProfileSuccess = { [weak self] user in
            guard let self = self else { return }
            MessageManager.shared.show(message: user.message, type: .success)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func clearAllErrors() {
        self.nameTextFieldView.hideErrorMessage()
        self.dobTextFieldView.hideErrorMessage()
        self.genderTextFieldView.hideErrorMessage()
    }
    
    private func handleRegistrationSuccess() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func createChildProfile() {
        Task {
            await self.viewModel.register()
        }
    }
    
    private func updateChildProfile(childId: String) {
        Task {
            await self.viewModel.registerToUpdate(childId: childId)
        }
    }
    
    func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: isoString) else { return isoString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd-MM-yyyy"
        return displayFormatter.string(from: date)
    }
}


extension ChildProfileViewController: AvatarPickerDelegate, DatePickerDelegate {
    
    func datePickerVCDidDismiss() {
        self.dobTextFieldView.hideErrorMessage()
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
    }
    
    func didSelectDOB(date: String) {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.dobTextFieldView.customTextField.text = date
    }
    
    func didSelectProfileImage(imageData: Data, image: UIImage) {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.addProfileImageView.image = UIImage(data: imageData)
        self.viewModel.profilePicture = image
    }
}


//08-05

extension ChildProfileViewController {
    
    private func setCreateChildProfileScreenUI() {
        self.setupGenderDropdown()
        self.backButton.isHidden = !self.IS_COMING_FROM_PROFILE_SCREEN
        
        self.appBGView.setGradientBackground()
        let title = self.selectedChild != nil ? "Update child profile" : APPConstants.createChidAcc

        self.headerLabel.text = title
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.addProfileView.layer.cornerRadius = 45
        self.addProfileView.layer.borderWidth = 1
        self.addProfileView.layer.borderColor = UIColor.borderColor.cgColor
        
        self.addProfileImageView.layer.cornerRadius = 45
        
        
        self.createChildProfileButton.setTitle(title, for: .normal)
        self.createChildProfileButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.createChildProfileButton.setTitleColor(.white, for: .normal)
        self.createChildProfileButton.backgroundColor = .pinkPrimaryColor
        self.createChildProfileButton.layer.cornerRadius = 25
       
        self.nameTextFieldView.customTextField.delegate = self
        self.nameTextFieldView.customTextField.setPlaceholder(text: APPConstants.fullNamePlaceholderForChild)
        self.nameTextFieldView.placeHolderLabel.text = APPConstants.fullNameTitle
        self.nameTextFieldView.customTextField.tag = 0
        
        self.genderTextFieldView.customTextField.delegate = self
        self.genderTextFieldView.customTextField.setPlaceholder(text: APPConstants.genderPlaceholder)
        self.genderTextFieldView.placeHolderLabel.text = APPConstants.genderTitle
        self.genderTextFieldView.customTextField.tag = 2
        self.genderTextFieldView.showRightView()
        
        self.dobTextFieldView.customTextField.delegate = self
        self.dobTextFieldView.customTextField.setPlaceholder(text: APPConstants.dobPlaceholder)
        self.dobTextFieldView.placeHolderLabel.text = APPConstants.dobTitle
        self.dobTextFieldView.customTextField.tag = 1
        self.dobTextFieldView.showRightView()

        [self.nameTextFieldView.customTextField, self.dobTextFieldView.customTextField, self.genderTextFieldView.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(genderFieldTapped))
        self.genderTextFieldView.customTextField.addGestureRecognizer(tap)
        self.genderTextFieldView.customTextField.isUserInteractionEnabled = true
        
        let dobTap = UITapGestureRecognizer(target: self, action: #selector(dobFieldTapped))
        self.dobTextFieldView.customTextField.addGestureRecognizer(dobTap)
        self.dobTextFieldView.customTextField.isUserInteractionEnabled = true
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
        case 0:
            self.nameTextFieldView.hideError()
            
        case 1:
            self.dobTextFieldView.hideErrorMessage()
            
        case 2:
            self.genderTextFieldView.hideErrorMessage()
            
        default:
            break
        }
    }
    
    @objc func genderFieldTapped() {
        self.view.endEditing(true)
        self.genderDropDown.show()
    }
    
    @objc func dobFieldTapped() {
        self.view.endEditing(true)
        self.openDatePickerVC()
    }
    
    private func setupGenderDropdown() {
        
        self.genderDropDown.anchorView = genderTextFieldView.customTextField
        self.genderDropDown.dataSource = ["Boy", "Girl"]
        self.genderDropDown.bottomOffset = CGPoint(
            x: 0,
            y: genderTextFieldView.customTextField.bounds.height
        )
        
        self.genderDropDown.selectionAction = { [weak self] index, item in
            self?.genderTextFieldView.customTextField.text = item
            self?.viewModel.childGender = item.lowercased()
            self?.genderTextFieldView.hideErrorMessage()
            
            // Set default avatar only if user hasn't selected a profile picture
            if self?.viewModel.profilePicture == nil {
                self?.viewModel.profilePicture = index == 0
                ? AppImages.boy_avatar_1
                : AppImages.girl_avatar_1
            }
        }
    }
    
    
    private func openDatePickerVC() {
        guard let contentVC = VCManager.openDatePickerVC() else { return }
        contentVC.delegate = self
        self.presentFloatingPanel(with: contentVC, layout: FloatingPanelCustomLayout(state: .half, inset: 0.55)
        )
    }

    private func openAvatarPickerVC() {
        guard let contentVC = VCManager.openAvatarPickerVC() else { return }
        contentVC.delegate = self
        self.presentFloatingPanel(with: contentVC, layout: FloatingPanelCustomLayout(state: .full, inset: 0.75)
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
        self.activityIndicatorView.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.activityIndicatorView.stopAnimating()
        self.view.sendSubviewToBack(self.activityView)
    }
}


extension ChildProfileViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
}


extension ChildProfileViewController: UITextFieldDelegate {
    
}

