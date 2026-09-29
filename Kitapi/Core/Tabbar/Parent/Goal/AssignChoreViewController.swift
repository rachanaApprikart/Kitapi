//
//  AssignChoreViewController.swift
//  Kitapi
//
//  Created by Suneel on 25/08/26.
//

import UIKit

class AssignChoreViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var availableChoresCV: UICollectionView!
    @IBOutlet weak var assignChoresButton: UIButton!
    
    private var availableChores: [TaskData] = []
    private var selectedChoreIDs = Set<String>()
    
    var goalId: String = ""

    private var selectedChores: [TaskData] {
        self.availableChores.filter {
            self.selectedChoreIDs.contains($0.id)
        }
    }
    private let assignChoreViewModel = AssignChoreViewModel()
    weak var delegate: AssignChoreDelegate?
    
    static var sbIdentifier: String {
        return String(describing: AssignChoreViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAssignChoresScreenUI()
        self.bindViewModel()
        self.getAvailableChoresInfo()
    }
    
    @IBAction func assignChoresAction(_ sender: UIButton) {
        let selectedIDs = Array(selectedChoreIDs)
        self.delegate?.didAssignChores(with: selectedIDs)
    }
    
    private func getAvailableChoresInfo() {
        Task {
            guard let childId = ChildManager.shared.selectedChild?.id else { return }
            await self.assignChoreViewModel.getAvailableChores(childId: childId)
        }
    }
    
    private func bindViewModel() {
        
        self.assignChoreViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
            isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.assignChoreViewModel.onGetAvailableChoresError = { [weak self] errorText in
            guard let self = self else { return }
            MessageManager.shared.show(message: errorText)
        }
        
        self.assignChoreViewModel.onGetAvailableChoresSuccess = { [weak self] choreResp in
            guard let self = self else { return }
            self.availableChores = choreResp.data.availableChores
            self.availableChoresCV.reloadData()
        }
    }
}

//MARK: -- 27 AUG

extension AssignChoreViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.availableChores.count
            
        case 1:
            return self.selectedChores.count
            
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            
            guard let listCVCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreListCVCell.reUseIdentifier, for: indexPath) as? ChoreListCVCell else {
                return UICollectionViewCell() }
            
            let chore = self.availableChores[indexPath.item]
            let isSelected = self.selectedChoreIDs.contains(chore.id)
            
            listCVCell.configureAvailableChores(with: chore, isSelected: isSelected)
            listCVCell.onSelectionTapped = { [weak self] in
                self?.toggleChoreSelection(chore.id)
            }
            return listCVCell
            
        } else {
            
            guard let selectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrentSelectionCVCell.reUseIdentifier, for: indexPath) as? CurrentSelectionCVCell else {
                return UICollectionViewCell() }
            
            let chore = self.selectedChores[indexPath.item]
            
            //template is only for the purpose of ui but we actually handling choreID
            guard let choreTemplate = self.selectedChores[indexPath.item].template else {
                return selectionCell
            }
            selectionCell.populateCurrentSelectionCell(templates: choreTemplate)
            
            selectionCell.onRemoveButtonTapped = { [weak self] in
                self?.removeSelectedChore(chore.id)
            }
            return selectionCell
        }
    }
    
    private func removeSelectedChore(_ choreID: String) {
        self.selectedChoreIDs.remove(choreID)
        self.availableChoresCV.reloadData()
    }
    
    private func toggleChoreSelection(_ choreID: String) {
        
        if self.selectedChoreIDs.contains(choreID) {
            self.selectedChoreIDs.remove(choreID)
        } else {
            self.selectedChoreIDs.insert(choreID)
        }
        self.availableChoresCV.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header2CVReusableView.reUseIdentifier, for: indexPath) as? Header2CVReusableView else {
            return UICollectionReusableView()
        }
        switch indexPath.section {
        case 0:
            headerView.headerLabel.text = APPConstants.assignChores
            
        case 1:
            if !self.selectedChores.isEmpty{
                headerView.headerLabel.text = "Selected Chores"
            } else {
                headerView.headerLabel.text = ""
            }
            
        default:
            headerView.headerLabel.text = ""
        }
        return headerView
    }
}


extension  AssignChoreViewController {
    
    private func setAssignChoresScreenUI() {
        self.appBGView.setGradientBackground()
        self.setAvailableChoreListCV()
        
        self.headerLabel.text = APPConstants.assignChores
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.assignChoresButton.setTitle(APPConstants.assignChores, for: .normal)
        self.assignChoresButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.assignChoresButton.setTitleColor(.white, for: .normal)
        self.assignChoresButton.backgroundColor = .pinkPrimaryColor
        self.assignChoresButton.layer.cornerRadius = 25
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, environment in

            switch sectionIndex {
            case 0:
                return self.createAvailableChoresSection()

            case 1:
                return self.createSelectedChoresSection()

            default:
                return nil
            }
        }
    }
    
    private func createAvailableChoresSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }
    
    private func createSelectedChoresSection() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .estimated(50))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }

    private func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(50)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
    
    private func setAvailableChoreListCV() {
        self.availableChoresCV.dataSource = self
        self.availableChoresCV.delegate = self
        self.availableChoresCV.showsVerticalScrollIndicator = false
        self.availableChoresCV.collectionViewLayout = self.createLayout()
        self.availableChoresCV.register(ChoreListCVCell.nibFile, forCellWithReuseIdentifier: ChoreListCVCell.reUseIdentifier)
        self.availableChoresCV.register(CurrentSelectionCVCell.nibFile, forCellWithReuseIdentifier: CurrentSelectionCVCell.reUseIdentifier)
        
        self.availableChoresCV.register(Header2CVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header2CVReusableView.reUseIdentifier)
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

protocol AssignChoreDelegate: AnyObject {
    func didAssignChores(with choreIDs: [String])
}
