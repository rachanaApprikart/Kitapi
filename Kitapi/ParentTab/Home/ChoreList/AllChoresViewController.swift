//
//  AllChoresViewController.swift
//  Kitapi
//
//  Created by Suneel on 15/11/26.
//

import UIKit

class AllChoresViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var choreTitleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var allChoresCV: UICollectionView!
    
    private let allChoresViewModel = AllChoreViewModel()
    private var selectedIndexPath: IndexPath? = IndexPath(item: 0, section: 0)
    
    static var sbIdentifier: String {
        return String(describing: AllChoresViewController.self)
    }
    
    private let choreStatuses: [ChoreStatus] = [.all, .upcoming, .pending, .completed, .rejected, .overdue]
    private var selectedStatus: ChoreStatus = .all
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAllChoresVCUI()
        self.bindViewModel()
        self.fetchChoresForSelectedChild()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func fetchChoresForSelectedChild() {
        
        guard let childId = ChildManager.shared.selectedChild?.id else {
            return
        }
        
        Task {
            await self.allChoresViewModel.fetchAllChores(childId: childId)
        }
    }
    
    private func bindViewModel() {
        
        self.allChoresViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.allChoresViewModel.onLoadingMoreChanged = { [weak self] isLoadingsMore in
            guard let self = self else { return }
            isLoadingsMore ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.allChoresViewModel.onErrorToGetAllChores = { errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.allChoresViewModel.onGetAllChoresSuccess = { [weak self] choreList in
            guard let self = self else { return }
            self.allChoresCV.reloadSections(IndexSet(integer: 1))
        }
        
        self.allChoresViewModel.onChoresUpdated = { [weak self] tasks in
            guard let self = self else { return }
            self.allChoresCV.reloadSections(IndexSet(integer: 1))
        }
    }
}


extension AllChoresViewController: UICollectionViewDataSource , UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
            
        case 0:
            return self.choreStatuses.count
            
        case 1:
            return self.allChoresViewModel.chores.count
            
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
            
        case 0:
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreStatusCVCell.reUseIdentifier, for: indexPath) as? ChoreStatusCVCell else {
                return UICollectionViewCell()
            }
            let isSelected = selectedIndexPath == indexPath

            let status = self.choreStatuses[indexPath.item]
            cell.configureStatusFilter(title: status.title, isSelected: isSelected)
            
            return cell
            
        case 1:
            
            guard let listCVCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreListCVCell.reUseIdentifier, for: indexPath) as? ChoreListCVCell else {
                return UICollectionViewCell()
            }
            let chore = allChoresViewModel.chores[indexPath.item]
            listCVCell.configureViewAllChores(with: chore)
            return listCVCell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        
        let status = self.choreStatuses[indexPath.item]
        
        guard selectedStatus != status else { return }
        
        let previousIndexPath = selectedIndexPath
        
        self.selectedStatus = status
        self.selectedIndexPath = indexPath
        
        var reloadItems: [IndexPath] = [indexPath]
        
        if let previousIndexPath,
           previousIndexPath != indexPath {
            reloadItems.append(previousIndexPath)
        }
        
        collectionView.reloadItems(at: reloadItems)
        
        guard let childId = ChildManager.shared.selectedChild?.id else {
            return
        }
        
        Task {
            await self.allChoresViewModel.changeStatus(status, childId: childId)
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        
        // Pagination only for chore list section
        guard indexPath.section == 1 else { return }
        
        let totalItems = allChoresViewModel.chores.count
        
        guard totalItems > 0 else { return }
        
        // Load next page when approaching last 3 cells
        if indexPath.item >= totalItems - 1 {
            
            guard let childId = ChildManager.shared.selectedChild?.id else {
                return
            }
            
            Task {
                await allChoresViewModel.loadMoreChores(childId: childId)
            }
        }
        
    }
}

extension ChoreStatus {

    var title: String {
        switch self {
        case .all:       return "All"
        case .upcoming:  return "Upcoming"
        case .pending:   return "Pending"
        case .completed: return "Completed"
        case .rejected:  return "Rejected"
        case .overdue:   return "Overdue"
        }
    }
}

extension AllChoresViewController {
    
    private func setAllChoresVCUI() {
        
        self.setChoreListCV()
        self.appBGView.setGradientBackground()
        
        self.choreTitleLabel.textColor = .headerLabekColor
        self.choreTitleLabel.textAlignment = .left
        self.choreTitleLabel.numberOfLines = 1
        self.choreTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 24)
        self.choreTitleLabel.text = "Chores"
    }
    
    private func setChoreListCV() {
        self.allChoresCV.dataSource = self
        self.allChoresCV.delegate = self
        self.allChoresCV.showsVerticalScrollIndicator = false
        self.allChoresCV.showsHorizontalScrollIndicator = false

        self.allChoresCV.register(ChoreListCVCell.nibFile, forCellWithReuseIdentifier: ChoreListCVCell.reUseIdentifier)
        self.allChoresCV.register(ChoreStatusCVCell.nibFile, forCellWithReuseIdentifier: ChoreStatusCVCell.reUseIdentifier)
        
        self.allChoresCV.collectionViewLayout = self.makeLayout()
    }
    
    private func makeLayout() -> UICollectionViewLayout {
        
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            
            guard let self else { return nil }
            
            switch sectionIndex {
            case 0:
                return self.makeHorizontalSection()
                
            case 1:
                return self.makeVerticalSection()
                
            default:
                return nil
            }
        }
    }

    private func makeHorizontalSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(90), heightDimension: .absolute(45))
           let item = NSCollectionLayoutItem(layoutSize: itemSize)

           let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(90), heightDimension: .absolute(45)
           )
           let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
           let section = NSCollectionLayoutSection(group: group)

           section.orthogonalScrollingBehavior = .continuous
           section.interGroupSpacing = 10
           section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
           return section
    }

    
    private func makeVerticalSection() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70))

        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize,subitems: [item])
        let section = NSCollectionLayoutSection(group: group)

        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
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
