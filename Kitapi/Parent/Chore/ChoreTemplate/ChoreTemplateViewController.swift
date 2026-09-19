//
//  ChoreTemplateViewController.swift
//  Kitapi
//
//  Created by Suneel on 23/06/26.
// 1 july

import UIKit
import FloatingPanel

class ChoreTemplateViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var choreTemplateView: UIView!
    @IBOutlet weak var templateSearchBar: UISearchBar!
    @IBOutlet weak var choreTemplateCV: UICollectionView!
    @IBOutlet weak var selectedChoreTemplateButton: UIButton!
    
    private let choreTemplateViewModel = ChoreTemplateViewModel()
    private var floatingPanel: FloatingPanelController?
    
    private var searching: Bool = false
    private var choreTemplateData: [TemplateData] = []
    private var searchChoreTemplateData: [TemplateData] = []
    private var currentSelection: TemplateData? = nil
    private var selectedTemplate: TemplateData? = nil

    private var selectedIndexPath: IndexPath?
    
    var onTemplateSelected: ((TemplateData) -> Void)?
    
    static var sbIdentifier: String {
        return String(describing: ChoreTemplateViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setChoreTemplateScreenUI()
        self.bindViewModel()
        self.getChoreTemplates()
    }
    
    private func bindViewModel() {
        
        self.choreTemplateViewModel.onError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.choreTemplateViewModel.onGetChoreTemplates = { [weak self] allTemplates in
            guard let self = self else { return }
            self.choreTemplateData = allTemplates.data
            
            if let selected = self.currentSelection,
               let match = self.choreTemplateData.first(where: { $0.id == selected.id }) {
                self.currentSelection = match
            }
            self.choreTemplateCV.reloadData()
        }
    }
    
    private func getChoreTemplates() {
        Task {
            await self.choreTemplateViewModel.getAllChoreTemplates()
        }
    }
    
    @IBAction func selectedChoreTemplateAction(_ sender: UIButton) {
        guard let selectedTemplate else { return }
        self.onTemplateSelected?(selectedTemplate)
    }
}
//MARK: DELEGATE METHODS

extension ChoreTemplateViewController: CreateTemplateDelegate {
    
    func didCreateTemplate(templateData: TemplateData) {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        
        self.currentSelection = templateData
        self.selectedTemplate = templateData
        
        if !self.choreTemplateData.contains(where: { $0.id == templateData.id }) {
            self.choreTemplateData.insert(templateData, at: 0)
        }
        
        self.searching = false
        self.searchChoreTemplateData.removeAll()
        self.templateSearchBar.text = ""
        self.choreTemplateCV.reloadData()
    }
}

//MARK: Search

extension ChoreTemplateViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
                
        if searchText.count == 0 {
            self.searching = false
        } else {
            let editingArray = self.choreTemplateData
            self.searchChoreTemplateData = editingArray.filter {
                return $0.title.lowercased().contains(searchText.lowercased())
            }
            self.searching = true
        }
        self.viewDidLayoutSubviews()
        self.choreTemplateCV.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
       
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}

//MARK: COLLECTION VIEW DELEGATES

extension ChoreTemplateViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if self.currentSelection != nil {
            return 2 //Current selection and suggestions
        }
        return self.searching ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Current Selection mode
        if self.currentSelection != nil {
            if section == 0 {
                return 1
            }
            return self.choreTemplateData.count
        }
        
        if self.searching {
            if section == 0 {
                //Search result else create new
                return self.searchChoreTemplateData.isEmpty ? 1 : self.searchChoreTemplateData.count
            } else {
                return self.choreTemplateData.count
            }
        } else {
            return self.choreTemplateData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let template: TemplateData
        
        if currentSelection != nil && indexPath.section == 0 {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrentSelectionCVCell.reUseIdentifier, for: indexPath) as?  CurrentSelectionCVCell else { return UICollectionViewCell() }
            
            if let selectedTemplate = self.currentSelection {
                cell.populateCurrentSelectionCell(templates: selectedTemplate)
            }
            cell.onRemoveButtonTapped = {
                self.currentSelection = nil
                self.selectedTemplate = nil
                self.selectedIndexPath = nil
                self.choreTemplateCV.reloadData()
            }
            return cell
        }
        if self.searching {
            if indexPath.section == 0 {
                
                if self.searchChoreTemplateData.isEmpty {
                    
                    guard let createTemplateCell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateChoreTemplateCVCell.reUseIdentifier, for: indexPath) as? CreateChoreTemplateCVCell else { return UICollectionViewCell() }
                    
                    createTemplateCell.createChoreTemplateLabel.text = self.templateSearchBar.text
                    createTemplateCell.onCreateChoreTemplateAction = {
                        self.presentFloatingPanel(layout: FloatingPanelCustomLayout(state: .full, inset: 0.75))
                    }
                    return createTemplateCell
                } else {
                    guard let templateCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreTemplateCVCell.reUseIdentifier, for: indexPath) as? ChoreTemplateCVCell else { return UICollectionViewCell() }
                    
                    template = self.searchChoreTemplateData[indexPath.item]
                    let isSelected = selectedIndexPath == indexPath
                    templateCell.populateTemplateCell(templates: template, isSelected: isSelected)
                    return templateCell
                }
            } else {
                guard let templateCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreTemplateCVCell.reUseIdentifier, for: indexPath) as? ChoreTemplateCVCell else { return UICollectionViewCell() }
                
                template = choreTemplateData[indexPath.item]
                let isSelected = selectedIndexPath == indexPath
                templateCell.populateTemplateCell(templates: template, isSelected: isSelected)
                return templateCell
            }
        } else {
            guard let templateCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreTemplateCVCell.reUseIdentifier, for: indexPath) as? ChoreTemplateCVCell else { return UICollectionViewCell() }
            
            template = choreTemplateData[indexPath.item]
            let isSelected = selectedIndexPath == indexPath
            templateCell.populateTemplateCell(templates: template, isSelected: isSelected)
            return templateCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Search mode + No search results
        
        if searching, indexPath.section == 0, searchChoreTemplateData.isEmpty {
            return
        }
        if searching && indexPath.section == 0 {
            selectedTemplate = searchChoreTemplateData[indexPath.item]
        } else {
            self.selectedTemplate = self.choreTemplateData[indexPath.item]
        }
        let previousIndexPath = selectedIndexPath
        selectedIndexPath = indexPath
        
        var reloadItems: [IndexPath] = [indexPath]
        
        if let previousIndexPath {
            reloadItems.append(previousIndexPath)
        }
        collectionView.reloadItems(at: reloadItems)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let maxWidth = collectionView.bounds.width - 20 // left + right insets
        
        if currentSelection != nil && indexPath.section == 0 {
            return CGSize(width: maxWidth, height: 70)
            
        }
        if searching && indexPath.section == 0 && searchChoreTemplateData.isEmpty {
            return CGSize(width: maxWidth, height: 100)
        }
        
        let title: String
        
        if searching && indexPath.section == 0 {
            title = searchChoreTemplateData[indexPath.item].title
        } else {
            title = choreTemplateData[indexPath.item].title
        }
        
        let calculatedWidth = title.size(
            withAttributes: [.font: UIFont(name: Fonts.urbanistBold, size: 14)!]).width + 65
        let finalWidth = min(calculatedWidth, maxWidth)
        
        return CGSize(width: finalWidth, height: 45)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header2CVReusableView.reUseIdentifier, for: indexPath) as? Header2CVReusableView else {
                return UICollectionReusableView()
            }
            
            if currentSelection != nil {
                
                if indexPath.section == 0 {
                    headerView.populateHeader(test: "Current Selection")
                } else {
                    headerView.populateHeader(test: "Suggestions")
                }
                
            }
            else if searching {
                
                if indexPath.section == 0 {
                    headerView.populateHeader(test: searchChoreTemplateData.isEmpty ? "" : "Search Results")
                } else {
                    headerView.populateHeader(test: "Suggestions")
                }
            }
            else {
                headerView.populateHeader(test: "Suggestions")
            }
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if currentSelection != nil {
            return CGSize(width: collectionView.frame.width, height: 50)
        }
        if searching && section == 0 && searchChoreTemplateData.isEmpty {
            return .zero
        }
        return CGSize(width: collectionView.frame.width, height: 50)
    }
}

extension ChoreTemplateViewController {
    
    private func setChoreTemplateScreenUI() {
        self.setChoreTemplateCV()
        self.appBGView.setGradientBackground()
       
        self.templateSearchBar.searchTextField.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.templateSearchBar.searchBarStyle = .minimal
        self.templateSearchBar.placeholder = APPConstants.searchChoreTitle
        self.templateSearchBar.delegate = self
        
        self.headerLabel.text = APPConstants.selectChoreTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.selectedChoreTemplateButton.setTitle(APPConstants.selectChoreTitle, for: .normal)
        self.selectedChoreTemplateButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.selectedChoreTemplateButton.setTitleColor(.white, for: .normal)
        self.selectedChoreTemplateButton.backgroundColor = .pinkPrimaryColor
        self.selectedChoreTemplateButton.layer.cornerRadius = 25
    }
    
    private func setChoreTemplateCV() {
        
        self.choreTemplateCV.delegate = self
        self.choreTemplateCV.dataSource = self
        self.choreTemplateCV.register(ChoreTemplateCVCell.nibFile, forCellWithReuseIdentifier: ChoreTemplateCVCell.reUseIdentifier)
        self.choreTemplateCV.register(CreateChoreTemplateCVCell.nibFile, forCellWithReuseIdentifier: CreateChoreTemplateCVCell.reUseIdentifier)
        self.choreTemplateCV.register(CurrentSelectionCVCell.nibFile, forCellWithReuseIdentifier: CurrentSelectionCVCell.reUseIdentifier)
       
        
        self.choreTemplateCV.register(Header2CVReusableView.nibFile, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header2CVReusableView.reUseIdentifier)
    }
    
    private func presentFloatingPanel(layout: FloatingPanelLayout) {
        guard floatingPanel == nil else { return }
        guard let contentVC = VCManager.openChoreTemplateImageVC() else { return }
        contentVC.selectedChore = self.templateSearchBar.text ?? ""
        contentVC.delegate = self
        
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

extension ChoreTemplateViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
