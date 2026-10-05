//
//  ViewAllChildProfilesVC.swift
//  Kitapi
//
//  Created by Suneel on 04/10/26.
//

import UIKit

class ViewAllChildProfilesVC: UIViewController {
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var childListTV: UITableView!
    
    private let viewAllProfilesViewModel = ViewAllChildProfilesViewModel()

    private var childrenList: [Child] = []
    private var selectedChildId: String?
    
    static var sbIdentifier: String {
        return String(describing: ViewAllChildProfilesVC.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setViewAllProfilesVC()
        self.bindViewModel()
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
            self.childrenList = childrenDetail.children
            self.childListTV.reloadData()
        }
    }
    
    private func getChildrenDetails() {
        Task {
            await self.viewAllProfilesViewModel.getDetailsOfChildren()
        }
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
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let child = self.childrenList[indexPath.row]
        self.selectedChildId = child.id
        self.childListTV.reloadData()
        ChildManager.shared.selectedChild = child
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
//actionSheetVC.actionSheetType = .childProfile
//actionSheetVC.childProfileDelegate = self
