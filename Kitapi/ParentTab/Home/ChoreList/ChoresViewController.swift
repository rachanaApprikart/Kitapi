//
//  ChoresViewController.swift
//  Kitapi
//
//  Created by Suneel on 21/05/26.
//

import UIKit
import FloatingPanel

class ChoresViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var choreView: UIView!
    @IBOutlet weak var choreTitleLabel: UILabel!
    @IBOutlet weak var choreSubtitleLabel: UILabel!
    @IBOutlet weak var addChoreButton: UIButton!

    @IBOutlet weak var noChoreView: UIView!
    @IBOutlet weak var noChoreSubtitleLabel: UILabel!
    @IBOutlet weak var noChoreTitleLabel: UILabel!
    @IBOutlet weak var addChoreBtnInNoChoreView: UIButton!
    
    @IBOutlet weak var choreListCV: UICollectionView!
    private var floatingPanel: FloatingPanelController?
    private let choresViewModel = ChoreViewModel()
    private var choreSection: [ChoreSection] = []
    
    static var sbIdentifier: String {
        return String(describing: ChoresViewController.self)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setChoresVCUI()        // 1. UI setup + registers .childDidChange observer
        self.bindViewModel()        // 2. wire up viewModel callbacks BEFORE any fetch can fire
        self.updateUIForSelectedChild()       // 3. update labels immediately (name may already be available)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchChoresForSelectedChild()
    }
    
    @IBAction func addChoreActionInNoChoreView(_ sender: UIButton) {
        self.showCreatChoreVC()
    }
    
    @IBAction func addChoreAction(_ sender: UIButton) {
        self.showCreatChoreVC()
    }
    
    @objc private func onChildChanged() {
        self.updateUIForSelectedChild()
        self.fetchChoresForSelectedChild()
    }
    
    private func bindViewModel() {
        
        self.choresViewModel.onLoadingChanged = { [weak self] isLoadings in
            guard let self = self else { return }
           isLoadings ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        self.choresViewModel.onErrorToGetAllChores = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.choresViewModel.onGetAllChoresSuccess = { [weak self] choreList in
            guard let self = self else { return }
            
            let task = choreList.data.tasks
            task.isEmpty ? self.showNoChoreView() : self.hideNoChoreView()
        }
        
        self.choresViewModel.onSectionsUpdated = { [weak self] sectionData in
            guard let self = self else { return }
            self.choreSection = sectionData
            self.choreListCV.reloadData()
        }
    }
    
    private func updateUIForSelectedChild() {
        guard let child = ChildManager.shared.selectedChild else {
            self.choreSubtitleLabel.text = ""
            self.noChoreSubtitleLabel.text = ""
            return
        }
        self.choreSubtitleLabel.text = "\(child.name) tasks"
        self.noChoreSubtitleLabel.text = "Add chore for \(child.name)"
    }
    
    private func fetchChoresForSelectedChild() {
        guard let childId = ChildManager.shared.selectedChild?.id else { return }
        
        Task {
            await self.choresViewModel.fetchAllChores(childId: childId)
        }
    }
    
    private func showCreatChoreVC() {
        guard let contentVC = VCManager.openCreateChoresVC() else { return }
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.95)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showChoreDetailsVC(cID: String) {
        guard let contentVC = VCManager.openChoreDetailsVC() else { return }
        contentVC.choreId = cID
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.85)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
   
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: ONCE CHORE IS CREATED/UPDATED SUCCESSFULLY

extension ChoresViewController: ChoreUpdateDelegate {
    
    func choreUpdatedSuccessfully() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.fetchChoresForSelectedChild()
    }
}

//24-07

extension ChoresViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.choreSection.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.choreSection[section].chores.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let section = self.choreSection[indexPath.section]
        let chore = section.chores[indexPath.item]


        guard let listCVCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreListCVCell.reUseIdentifier, for: indexPath) as? ChoreListCVCell else {
            return UICollectionViewCell() }

        listCVCell.configure(with: chore, sectionType: section.type)
        return listCVCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let choreId = self.choreSection[indexPath.section].chores[indexPath.item].id
        self.showChoreDetailsVC(cID: choreId)
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header2CVReusableView.reUseIdentifier, for: indexPath) as? Header2CVReusableView else {
            return UICollectionReusableView()
        }

        let section = self.choreSection[indexPath.section]
        headerView.headerLabel.text = section.type.title
        return headerView
    }
}
//03-06-2026


extension ChoresViewController {
    
    private func setChoresVCUI() {
        self.appBGView.setGradientBackground()
        self.setChoreListCV()
        self.choreListCV.collectionViewLayout = self.makeLayout()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onChildChanged),
            name: .childDidChange,
            object: nil
        )
        
        self.choreTitleLabel.textColor = .headerLabekColor
        self.choreTitleLabel.textAlignment = .left
        self.choreTitleLabel.numberOfLines = 1
        self.choreTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 24)
        self.choreTitleLabel.text = "Chores"

        self.choreSubtitleLabel.textColor = .headerLabekColor
        self.choreSubtitleLabel.textAlignment = .left
        self.choreSubtitleLabel.numberOfLines = 1
        self.choreSubtitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 12)

        self.addChoreButton.setTitle("Add", for: .normal)
        self.addChoreButton.titleLabel?.font = UIFont(name: Fonts.urbanistExtraBold, size: 14)
        self.addChoreButton.setTitleColor(.white, for: .normal)
        self.addChoreButton.backgroundColor = .pinkPrimaryColor
        self.addChoreButton.layer.cornerRadius = 10
        
        self.noChoreTitleLabel.textColor = .headerLabekColor
        self.noChoreTitleLabel.textAlignment = .center
        self.noChoreTitleLabel.numberOfLines = 1
        self.noChoreTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 20)
        self.noChoreTitleLabel.text = "No Chores"
        
        self.noChoreSubtitleLabel.textColor = .headerLabekColor
        self.noChoreSubtitleLabel.textAlignment = .center
        self.noChoreSubtitleLabel.numberOfLines = 1
        self.noChoreSubtitleLabel.font = UIFont(name: Fonts.urbanistMedium, size: 12)
        
        self.addChoreBtnInNoChoreView.setTitle("Add Chore", for: .normal)
        self.addChoreBtnInNoChoreView.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.addChoreBtnInNoChoreView.setTitleColor(.white, for: .normal)
        self.addChoreBtnInNoChoreView.backgroundColor = .pinkPrimaryColor
        self.addChoreBtnInNoChoreView.layer.cornerRadius = 20
    }
    
    private func setChoreListCV() {
        self.choreListCV.dataSource = self
        self.choreListCV.delegate = self
        self.choreListCV.showsVerticalScrollIndicator = false
        self.choreListCV.register(ChoreListCVCell.nibFile, forCellWithReuseIdentifier: ChoreListCVCell.reUseIdentifier)
        self.choreListCV.register(Header2CVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header2CVReusableView.reUseIdentifier)
    }
    
    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }

            let section = self.choreSection[sectionIndex]
            return section.type.isHorizontal ? self.makeHorizontalSection(): self.makeVerticalSection()
        }
    }

    private func makeHorizontalSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(90)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.95),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 15)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging // matches the dot-page-indicator in your screenshot
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }

    private func makeVerticalSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(70)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(70)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
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
    
    private func showNoChoreView() {
        self.noChoreView.isHidden = false
        self.view.bringSubviewToFront(self.noChoreView)
        
        self.choreView.isHidden = true
        self.view.sendSubviewToBack(self.choreView)
    }
    
    private func hideNoChoreView() {
        self.noChoreView.isHidden = true
        self.view.sendSubviewToBack(self.noChoreView)

        self.choreView.isHidden = false
        self.view.bringSubviewToFront(self.choreView)
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
}

extension ChoresViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}

