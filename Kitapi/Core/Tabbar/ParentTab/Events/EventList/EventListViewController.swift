//
//  EventListViewController.swift
//  Kitapi
//
//  Created by Suneel Apprikart on 07/10/26.
//

import UIKit
import FloatingPanel

class EventListViewController: UIViewController {

    @IBOutlet weak var appBgView: UIView!
    @IBOutlet weak var headerView: PersistentHeaderView!
    
    @IBOutlet weak var mainView: UIView!
    
    
    
    private var floatingPanel: FloatingPanelController?
    var eventListVM = EventListViewModel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let backgroundGradient = CAGradientLayer()
    private let tabs = UIStackView()
    private var filterTabs: [EventFilterTab] = []
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let stateLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var loadTask: Task<Void, Never>?
    private var mpinTask: Task<Void, Never>?
    private var renderedEventIDs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUpEventListVCUI()
        configureEventList()
        eventListVM.onChange = { [weak self] in self?.renderEvents() }
        reloadEvents()
    }

    deinit {
        loadTask?.cancel()
        mpinTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundGradient.frame = appBgView.bounds
        CATransaction.commit()
    }

    private func configureEventList() {
        mainView.backgroundColor = .clear
        let filterSurface = UIView()
        filterSurface.backgroundColor = .white
        filterSurface.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(filterSurface)
        NSLayoutConstraint.activate([
            filterSurface.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            filterSurface.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            filterSurface.topAnchor.constraint(equalTo: mainView.topAnchor),
            filterSurface.heightAnchor.constraint(equalToConstant: 68)
        ])
        tabs.axis = .horizontal
        tabs.spacing = 0
        tabs.distribution = .fillProportionally
        for filter in EventListFilter.allCases {
            let tab = EventFilterTab(title: filter.title) { [weak self] in self?.reloadEvents(filter: filter) }
            tab.button.accessibilityIdentifier = "events.filter.\(filter.rawValue)"
            tabs.addArrangedSubview(tab)
            filterTabs.append(tab)
        }
        let heading = UILabel()
        heading.text = "Events"
        heading.font = UIFont(name: Fonts.urbanistBold, size: 24) ?? .boldSystemFont(ofSize: 24)
        heading.textColor = .headerLabekColor
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 145
        tableView.contentInset.bottom = 16
        tableView.register(EventCardCell.self, forCellReuseIdentifier: EventCardCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "events.list"
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshEvents), for: .valueChanged)
        for subview in [tabs, heading, tableView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            tabs.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 8),
            tabs.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 16),
            tabs.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -16),
            tabs.heightAnchor.constraint(equalToConstant: 60),
            heading.topAnchor.constraint(equalTo: tabs.bottomAnchor, constant: 16),
            heading.leadingAnchor.constraint(equalTo: tabs.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: tabs.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: tabs.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        stateLabel.numberOfLines = 0
        stateLabel.textAlignment = .center
        stateLabel.textColor = .labelPlaceholderColor
        stateLabel.font = UIFont(name: Fonts.urbanistMedium, size: 16) ?? .systemFont(ofSize: 16)
        retryButton.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 16) ?? .boldSystemFont(ofSize: 16)
        retryButton.tintColor = .pinkPrimaryColor
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.addTarget(self, action: #selector(retryEvents), for: .touchUpInside)
        let stateStack = UIStackView(arrangedSubviews: [loadingIndicator, stateLabel, retryButton])
        stateStack.axis = .vertical
        stateStack.spacing = 16
        stateStack.alignment = .center
        let stateView = UIView()
        stateStack.translatesAutoresizingMaskIntoConstraints = false
        stateView.addSubview(stateStack)
        NSLayoutConstraint.activate([
            stateStack.centerXAnchor.constraint(equalTo: stateView.centerXAnchor),
            stateStack.centerYAnchor.constraint(equalTo: stateView.centerYAnchor),
            stateStack.leadingAnchor.constraint(greaterThanOrEqualTo: stateView.leadingAnchor, constant: 24),
            stateStack.trailingAnchor.constraint(lessThanOrEqualTo: stateView.trailingAnchor, constant: -24)
        ])
        tableView.backgroundView = stateView
    }

    @objc private func refreshEvents() { reloadEvents() }

    @objc private func retryEvents() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in await self?.eventListVM.loadNextPage() }
    }

    private func reloadEvents(filter: EventListFilter? = nil) {
        if let filter, filter == eventListVM.filter { return }
        loadTask?.cancel()
        loadTask = Task { [weak self] in await self?.eventListVM.reload(filter: filter) }
    }

    private func renderEvents() {
        for (index, filter) in EventListFilter.allCases.enumerated() {
            filterTabs[index].setSelected(filter == eventListVM.filter)
        }
        let ids = eventListVM.events.map(\.id)
        if ids != renderedEventIDs {
            let previousIDs = renderedEventIDs
            renderedEventIDs = ids
            if !previousIDs.isEmpty, ids.starts(with: previousIDs), ids.count > previousIDs.count {
                tableView.insertRows(at: (previousIDs.count..<ids.count).map { IndexPath(row: $0, section: 0) }, with: .none)
            } else {
                tableView.reloadData()
            }
        }
        let empty = eventListVM.events.isEmpty
        tableView.backgroundView?.isHidden = !empty
        stateLabel.isHidden = eventListVM.isLoading
        stateLabel.text = eventListVM.errorMessage ?? "No \(eventListVM.filter == .all ? "" : eventListVM.filter.rawValue + " ")events yet.\nPull down to refresh."
        retryButton.isHidden = eventListVM.errorMessage == nil
        eventListVM.isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        if !eventListVM.isLoading { refreshControl.endRefreshing() }
        if !empty {
            let footer = UIButton(type: .system)
            footer.titleLabel?.font = UIFont(name: Fonts.urbanistMedium, size: 14) ?? .systemFont(ofSize: 14)
            footer.tintColor = .labelPlaceholderColor
            footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 48)
            footer.setTitle(eventListVM.isLoading ? "Loading more events…" : (eventListVM.errorMessage != nil ? "Couldn't load more. Tap to retry" : "Load more"), for: .normal)
            footer.isEnabled = !eventListVM.isLoading
            footer.addTarget(self, action: #selector(retryEvents), for: .touchUpInside)
            tableView.tableFooterView = eventListVM.canLoadMore || eventListVM.isLoading ? footer : nil
        } else {
            tableView.tableFooterView = nil
        }
    }
    


}


extension EventListViewController {
    
    private func setUpEventListVCUI() {
        backgroundGradient.colors = [UIColor.gradientColor1.cgColor, UIColor.gradientColor2.cgColor, UIColor.gradientColor3.cgColor]
        backgroundGradient.locations = [0, 0.5, 1]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0.5, y: 1)
        appBgView.layer.insertSublayer(backgroundGradient, at: 0)

        self.headerView.onChildSelectionTapped = { [weak self] in
            self?.showChildSelectionPanel()
        }
        
        self.headerView.onToggleChildMode = { [weak self]  isSwitchOn in
            self?.childModeButtonTapped()
        }
        
        //To observe change in child selection, so that UI and API can be refreshed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onChildChanged),
            name: .childDidChange,
            object: nil
        )
   
    }
    
    //Mostly it will fetch mpinStatus in homeVC. Incase if MPIN is created in analyticsVC, the delegate has to refresh the status. hence getMPINStatus
    
    private func childModeButtonTapped() {
       
        if MPINManager.shared.hasFetchedStatus {
            
            if MPINManager.shared.isSetup {
                self.showSetTimerPanel()
            } else {
                self.showMPINPanel()
            }
        } else {
            self.getMPINStatus()
        }
    }
    
    @objc private func onChildChanged() {
        // The list is parent-wide; refresh after switching profiles without sending an unsupported childId filter.
        reloadEvents()
    }
    
 
    
    private func showChildSelectionPanel() {
        guard let contentVC = VCManager.openChildListVC() else { return }
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.5)
        contentVC.childrenList = ChildManager.shared.children
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showSetTimerPanel() {
        guard let contentVC = VCManager.opensetTimerVC() else { return }
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.52)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func showMPINPanel() {
        guard let contentVC = VCManager.openMPINVC() else { return }
        contentVC.delegate = self
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.6)
        self.presentFloatingPanel(with: contentVC, layout: layout)
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
   
    private func getMPINStatus(presentNextPanel: Bool = true) {
        guard mpinTask == nil else { return }
        mpinTask = Task { [weak self] in
            guard let self else { return }
            defer { self.mpinTask = nil }
            do {
                let response = try await MPINService().getMPINStatus()
                guard let status = response.data, status.success else {
                    EventAPILog.write("[EventList][MPIN] GET /api/child-mode/parent/mpin/status FAILED status=\(response.statusCode.map(String.init) ?? "none") reason=\(response.error.map { EventAPILog.errorSummary($0) } ?? "Unsuccessful or missing response")")
                    MessageManager.shared.show(message: "Unable to check PIN status. Please try again.")
                    return
                }
                MPINManager.shared.update(with: status.data)
                if presentNextPanel { self.childModeButtonTapped() }
            } catch {
                EventAPILog.write("[EventList][MPIN] GET /api/child-mode/parent/mpin/status FAILED reason=\(EventAPILog.errorSummary(error))")
                MessageManager.shared.show(message: error.localizedDescription)
            }
        }
    }
    
}
extension EventListViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}

extension EventListViewController: CreateMPINDelegate {
   //Incase if mpin is created in analytics tab, to refresh the status
    func mpinCreatedSuccessfully() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.getMPINStatus(presentNextPanel: false)
    }
}

extension EventListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard eventListVM.events.indices.contains(indexPath.row),
              let navigationController,
              !(navigationController.topViewController is EventDetailsViewController),
              let detailsVC = VCManager.openEventDetailsVC() else { return }
        detailsVC.selectedEvent = eventListVM.events[indexPath.row]
        detailsVC.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(detailsVC, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { eventListVM.events.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard eventListVM.events.indices.contains(indexPath.row),
              let cell = tableView.dequeueReusableCell(withIdentifier: EventCardCell.reuseIdentifier, for: indexPath) as? EventCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: eventListVM.events[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row >= eventListVM.events.count - 3, eventListVM.canLoadMore, eventListVM.errorMessage == nil else { return }
        loadTask = Task { [weak self] in await self?.eventListVM.loadNextPage() }
    }
}
