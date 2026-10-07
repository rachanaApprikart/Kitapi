//
//  ViewAllChildProfilesVC.swift
//  Kitapi
//
//  Created by Suneel on 04/10/26.
//

import UIKit
import FloatingPanel

class ViewAllChildProfilesVC: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var childListTV: UITableView!
    
    private let viewAllProfilesViewModel = ViewAllChildProfilesViewModel()
    private var floatingPanel: FloatingPanelController?

    private var childrenList: [Child] = []
    private var selectedChildId: String?
    
    static var sbIdentifier: String {
        return String(describing: ViewAllChildProfilesVC.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setViewAllProfilesVC()
        self.bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getChildrenDetails()
    }
    
     @IBAction func backAction(_ sender: UIButton) {
         self.navigationController?.popToRootViewController(animated: true)
     }

    private func bindViewModel() {
        
        self.viewAllProfilesViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.viewAllProfilesViewModel.onGetChildDetailsError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewAllProfilesViewModel.onGetChildDetailsSuccess = { [weak self] childrenDetail in
            guard let self = self else { return }
            ChildManager.shared.setChildren(childrenDetail.children)
            self.childrenList = childrenDetail.children
            self.childListTV.reloadData()
        }
        
        self.viewAllProfilesViewModel.onDeleteChildProfileError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewAllProfilesViewModel.onDeleteChildProfileSuccess = { [weak self] childrenDetail in
            guard let self = self else { return }
            // Delete API does not return the updated children list.
            // Fetch the latest children from the server.
            self.getChildrenDetails()
        }
    }
    
    private func getChildrenDetails() {
        Task {
            await self.viewAllProfilesViewModel.getDetailsOfChildren()
        }
    }
    
    private func deleteChildProfile() {
        
        guard let id = self.selectedChildId else { return }
        
        Task {
            await self.viewAllProfilesViewModel.deleteChildProfile(childId: id)
        }
    }
    
    private func openEditChildProfileVC(details: Child?) {
        guard let vc = VCManager.openCreateChildProfileVC() else { return }
        vc.selectedChild = details
        vc.IS_COMING_FROM_PROFILE_SCREEN = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewAllChildProfilesVC: ChildProfileActionSheetDelegate {
 
    func didTapEditChild(details: Child?) {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.openEditChildProfileVC(details: details)
    }
    
    func didTapDeleteChild() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.deleteChildProfile()
    }
}


//MARK: TABLE VIEW DELEGATES

extension ViewAllChildProfilesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.childrenList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChildListTVCell.reUseIdentifier, for: indexPath) as? ChildListTVCell else { return UITableViewCell () }
        
        let child = self.childrenList[indexPath.row]
        cell.populateCell(with: child, isSelected: child.id == selectedChildId)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 + 12
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let child = self.childrenList[indexPath.row]
        self.selectedChildId = child.id
        self.childListTV.reloadData()
        self.showActionSheetVC(details: child)
    }
}

extension ViewAllChildProfilesVC {
    
    private func setViewAllProfilesVC() {
        
        self.appBGView.setGradientBackground()
                
        self.headerLabel.text = "Child Profiles"
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.childListTV.delegate = self
        self.childListTV.dataSource = self
        self.childListTV.separatorStyle = .none
        self.childListTV.register(ChildListTVCell.nibFile, forCellReuseIdentifier: ChildListTVCell.reUseIdentifier)
    }
    
    private func showActionSheetVC(details: Child) {
        guard let actionSheetVC = VCManager.openActionSheetVC() else { return }
        actionSheetVC.actionSheetType = .childProfile
        actionSheetVC.childDetails = details
        actionSheetVC.childProfileDelegate = self
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.4)
        self.presentFloatingPanel(with: actionSheetVC, layout: layout)
    }
    
    private func presentFloatingPanel(with contentVC: UIViewController, layout: FloatingPanelLayout) {
        guard floatingPanel == nil else { return }
        
        let fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        
        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false
        fpc.layout = layout
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

extension ViewAllChildProfilesVC: FloatingPanelControllerDelegate, UITextFieldDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}

