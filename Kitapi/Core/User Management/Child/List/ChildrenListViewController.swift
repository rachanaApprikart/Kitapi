//
//  ChildrenListViewController.swift
//  Kitapi
//
//  Created by Suneel on 29/05/26.
//

import UIKit

class ChildrenListViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var childListTV: UITableView!
    
    var childrenList: [Child] = []
    private var selectedChildId: String?
    
    static var sbIdentifier: String {
        return String(describing: ChildrenListViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setChildListUI()
        // Do any additional setup after loading the view.
    }
}

extension ChildrenListViewController: UITableViewDelegate, UITableViewDataSource {
    
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


  


//MARK: ------- UI --------

//30-5

extension ChildrenListViewController {
    
    private func setChildListUI() {
        self.headerLabel.text = APPConstants.profileSwitchTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.childListTV.delegate = self
        self.childListTV.dataSource = self
        self.childListTV.separatorStyle = .none
        self.childListTV.register(ChildListTVCell.nibFile, forCellReuseIdentifier: ChildListTVCell.reUseIdentifier)
    
      
    }
}
