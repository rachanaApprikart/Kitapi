import UIKit
import Kingfisher
import SafariServices

final class EventDetailsViewController: UIViewController {
    var selectedEvent: KitapiEvent?
    var eventId: String? { selectedEvent?.id }
    var eventDetailsVM = EventDetailsViewModel()
    static var sbIdentifier: String { String(describing: EventDetailsViewController.self) }

    let tableView = UITableView(frame: .zero, style: .plain)
    let header = UIView()
    let heroContainer = UIView()
    lazy var heroPager: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    let imagePages = UIPageControl()
    let navigationOverlay = UIView()
    let compactTitle = UILabel()
    let navigationBack = UIButton(type: .system)
    private var headerImages: [URL] = []
    let visibleTabs: [EventDetailsTab] = [.about]
    let statusLabel = UILabel()
    let categoryLabel = UILabel()
    let categoryPill = UIView()
    var categoryPillWidth: NSLayoutConstraint?
    let eventTitleLabel = UILabel()
    let dateLabel = UILabel()
    let tabStack = UIStackView()
    var tabs: [EventFilterTab] = []
    let footer = UIStackView()
    let consentButton = UIButton(type: .system)
    var consentRow: UIStackView?
    var checkout: any EventCheckoutPresenting = EventCheckout()
    var errorPresenter: (String) -> Void = { MessageManager.shared.show(message: $0, type: .error) }
    let bookingButton = UIButton(type: .system)
    let bookingMessage = UILabel()
    let detailsRetryButton = UIButton(type: .system)
    let loading = UIActivityIndicatorView(style: .medium)
    let moreButton = UIButton(type: .system)
    let backgroundGradient = CAGradientLayer()
    var collapsedFooter: NSLayoutConstraint?
    private var detailTask: Task<Void, Never>?
    private var participantTask: Task<Void, Never>?
    private var registrationTask: Task<Void, Never>?
    private var availabilityTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedEvent?.title ?? "Event Details"
        buildUI()
        eventDetailsVM.onChange = { [weak self] in self?.render() }
        NotificationCenter.default.addObserver(self, selector: #selector(childChanged), name: .childDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(childChanged), name: .childModeDidChange, object: nil)
        if let selectedEvent { renderHeader(selectedEvent) }
        reloadDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        availabilityTask?.cancel()
        availabilityTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.renderBooking()
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        availabilityTask?.cancel()
        availabilityTask = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundGradient.frame = view.bounds
        CATransaction.commit()
        updateHeaderHeight()
        if let flow = heroPager.collectionViewLayout as? UICollectionViewFlowLayout, flow.itemSize != heroPager.bounds.size, heroPager.bounds.width > 0 {
            flow.itemSize = heroPager.bounds.size
        }
        updateCollapsingHeader()
    }

    deinit {
        detailTask?.cancel()
        participantTask?.cancel()
        registrationTask?.cancel()
        availabilityTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func childChanged() {
        eventDetailsVM.hasAgreedTerms = false
        render()
    }

    @objc func reloadDetails() {
        guard let eventId else { bookingMessage.text = "Event information is unavailable."; return }
        detailTask?.cancel()
        participantTask?.cancel()
        detailTask = Task { [weak self] in
            guard let self else { return }
            await self.eventDetailsVM.load(eventID: eventId)
            if self.eventDetailsVM.selectedTab == .participation { self.loadParticipants() }
        }
    }

    func selectTab(_ tab: EventDetailsTab) {
        guard visibleTabs.contains(tab) else { return }
        eventDetailsVM.selectedTab = tab
        render()
        if tab == .participation, eventDetailsVM.participants.isEmpty, eventDetailsVM.canLoadParticipants { loadParticipants() }
    }

    @objc func loadParticipants() {
        guard let eventId, eventDetailsVM.canLoadParticipants else { return }
        participantTask = Task { [weak self] in await self?.eventDetailsVM.loadParticipants(eventID: eventId) }
    }

    @objc func toggleConsent() {
        eventDetailsVM.hasAgreedTerms.toggle()
        renderBooking()
    }

    @objc func participate() {
        guard let eventId, !eventDetailsVM.isRegistering else { return }
        if eventDetailsVM.isRegistered(childID: ChildManager.shared.selectedChild?.id) { openGroup(); return }
        if eventDetailsVM.hasPendingVerification(childID: ChildManager.shared.selectedChild?.id) { retryPaymentVerification(); return }
        if eventDetailsVM.bookingKind == .paid { chooseBatch(); return }
        registrationTask = Task { [weak self] in
            guard let self else { return }
            await self.eventDetailsVM.register(eventID: eventId, childID: ChildManager.shared.selectedChild?.id, isChildMode: ChildManager.shared.isChildMode)
            self.showRegistrationFailureIfNeeded()
        }
    }

    func render() {
        if let event = eventDetailsVM.details?.event { renderHeader(event) }
        for (index, tab) in visibleTabs.enumerated() { tabs[index].setSelected(tab == eventDetailsVM.selectedTab) }
        let busy = eventDetailsVM.selectedTab == .about ? eventDetailsVM.isLoading : eventDetailsVM.participantsLoading
        busy ? loading.startAnimating() : loading.stopAnimating()
        tableView.reloadData()
        let participantError = eventDetailsVM.participantsError != nil
        moreButton.isHidden = eventDetailsVM.selectedTab != .participation || (!eventDetailsVM.canLoadParticipants && !participantError)
        moreButton.setTitle(participantError ? "Try Again" : "Load More", for: .normal)
        moreButton.isEnabled = !eventDetailsVM.participantsLoading
        tableView.tableFooterView = moreButton.isHidden ? nil : moreButton
        renderBooking()
        updateHeaderHeight()
    }

    private func renderHeader(_ event: KitapiEvent) {
        eventTitleLabel.text = event.title
        categoryLabel.text = event.category?.isEmpty == false ? event.category : "Event"
        let categoryFont = categoryLabel.font ?? UIFont.systemFont(ofSize: 13)
        categoryPillWidth?.constant = ceil(((categoryLabel.text ?? "Event") as NSString).size(withAttributes: [.font: categoryFont]).width) + 25
        categoryPill.backgroundColor = EventCardStyle.categoryTint(event.category)
        dateLabel.text = EventDateText.range(start: event.startDate, end: event.endDate)
        statusLabel.text = "  \(event.displayStatus)  "
        statusLabel.backgroundColor = event.status.lowercased() == "live" ? .greenPrimaryColor : (event.status.lowercased() == "upcoming" ? .orangePrimaryColor : .buttonBackgroundColor)
        compactTitle.text = event.title
        let values = eventDetailsVM.details?.images.compactMap(\.url) ?? event.imageUrl?.url.map { [$0] } ?? []
        let urls = values.compactMap { URL(string: $0) }.filter { ["https", "http"].contains($0.scheme?.lowercased() ?? "") }
        if urls != headerImages {
            headerImages = urls
            heroPager.reloadData()
            imagePages.numberOfPages = urls.count
            imagePages.isHidden = urls.count < 2
            imagePages.currentPage = 0
            heroPager.setContentOffset(.zero, animated: false)
        }
    }

    private func renderBooking() {
        let vm = eventDetailsVM
        navigationBack.isEnabled = !vm.isRegistering
        let child = ChildManager.shared.selectedChild
        let registered = vm.isRegistered(childID: child?.id)
        let open = vm.details?.acceptsRegistration == true
        let pendingVerification = vm.hasPendingVerification(childID: child?.id)
        consentButton.isSelected = vm.hasAgreedTerms
        consentButton.setImage(UIImage(systemName: vm.hasAgreedTerms ? "checkmark.square.fill" : "square"), for: .normal)
        consentButton.accessibilityValue = vm.hasAgreedTerms ? "Accepted" : "Not accepted"
        var label = "Participate"
        var message = vm.bookingError ?? vm.errorMessage
        if vm.isLoading { label = "Loading…" }
        else if registered { label = vm.groupURL(childID: child?.id) == nil ? "Registered" : "Join WhatsApp Group"; message = "\(child?.name ?? "Your child") is registered for this event." }
        else if !open, vm.details != nil { label = "Registration Closed" }
        else if vm.bookingKind == .paid {
            if vm.paidRegistrations.contains(where: { $0.ownerChildID == child?.id && !$0.isConfirmed }) { label = "Continue Payment" }
            else if vm.batches.count == 1, let amount = vm.batches.first?.feeAmount { label = "Pay \(amount.display) to Participate" }
            else { label = "Select Batch & Pay" }
        }
        else if vm.bookingKind == .unknown || !vm.registrationChecked { label = "Registration Unavailable" }
        else if ChildManager.shared.isChildMode { message = "Exit child mode to register." }
        else if child == nil { message = "Select a child on the Events screen before registering." }
        else if message == nil { message = "Register \(child?.name ?? "your child") for this event." }
        if vm.isRegistering { label = vm.bookingKind == .paid ? "Processing payment…" : "Registering…" }
        else if pendingVerification && !registered { label = "Retry Payment Verification" }
        bookingButton.setTitle(label, for: .normal)
        bookingButton.isEnabled = !vm.isLoading && !vm.isRegistering && !ChildManager.shared.isChildMode && (registered ? vm.groupURL(childID: child?.id) != nil : pendingVerification || (open && vm.bookingKind != .unknown && vm.registrationChecked && child != nil && vm.hasAgreedTerms))
        bookingButton.backgroundColor = registered ? .greenPrimaryColor : .pinkPrimaryColor
        bookingButton.alpha = bookingButton.isEnabled ? 1 : 0.55
        bookingMessage.text = message
        bookingMessage.isHidden = message == nil
        footer.isHidden = vm.details != nil && !open && !registered && !pendingVerification
        footer.layoutMargins = footer.isHidden ? .zero : UIEdgeInsets(top: 10, left: 16, bottom: 12, right: 16)
        for arranged in footer.arrangedSubviews { arranged.isHidden = footer.isHidden }
        consentRow?.isHidden = footer.isHidden || registered || pendingVerification
        bookingMessage.isHidden = footer.isHidden || message == nil
        detailsRetryButton.isHidden = footer.isHidden || (vm.bookingError == nil && vm.errorMessage == nil) || vm.isLoading || registered
        collapsedFooter?.isActive = footer.isHidden
    }

    private func updateHeaderHeight() {
        guard tableView.bounds.width > 0 else { return }
        let size = header.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        if abs(header.frame.height - size.height) > 0.5 || header.frame.width != tableView.bounds.width {
            let offset = tableView.contentOffset
            header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: size.height)
            header.setNeedsLayout()
            header.layoutIfNeeded()
            tableView.tableHeaderView = header
            tableView.setContentOffset(offset, animated: false)
        }
    }

    func updateCollapsingHeader() {
        let offset = max(0, tableView.contentOffset.y + tableView.adjustedContentInset.top)
        let heroHeight = heroContainer.bounds.height
        guard heroHeight > 0, eventTitleLabel.bounds.height > 0 else {
            compactTitle.alpha = 0
            navigationOverlay.backgroundColor = .clear
            heroPager.alpha = 1
            heroPager.transform = .identity
            navigationBack.backgroundColor = .white
            return
        }
        let navigationHeight = max(56, navigationOverlay.bounds.height)
        let progress = min(1, offset / max(1, heroHeight - navigationHeight))
        navigationOverlay.backgroundColor = UIColor.gradientColor1.withAlphaComponent(progress)
        // Only reveal the compact title after the image and full title have passed behind the opaque header.
        let titleBottom = eventTitleLabel.convert(eventTitleLabel.bounds, to: header).maxY
        let threshold = max(heroHeight, titleBottom) - navigationHeight
        compactTitle.alpha = min(1, max(0, (offset - threshold) / 24))
        heroPager.alpha = 1 - progress * 0.35
        heroPager.transform = UIAccessibility.isReduceMotionEnabled ? .identity : CGAffineTransform(translationX: 0, y: offset * 0.2)
        navigationBack.backgroundColor = UIColor.white.withAlphaComponent(1 - progress)
    }

    func openPolicy(_ value: String?, fallback: String) {
        guard let url = EventLegalLinks.url(apiValue: value ?? fallback, configurationKey: "") else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}

extension EventDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    private var aboutRows: [(String?, String?, String)] {
        guard let details = eventDetailsVM.details else { return [("Event Details", nil, eventDetailsVM.errorMessage ?? "Loading event information…")] }
        var rows: [(String?, String?, String)] = [("Event description", nil, details.description?.isEmpty == false ? details.description ?? "" : "No description has been added yet.")]
        let steps = details.instructions.sorted { $0.step < $1.step }
        if steps.isEmpty { rows.append(("Instructions for the event", nil, "Instructions have not been added yet.")) }
        for (index, instruction) in steps.enumerated() { rows.append((index == 0 ? "Instructions for the event" : nil, "Step : \(instruction.step)", instruction.text)) }
        if let prizes = details.prizesDescription, !prizes.isEmpty { rows.append(("Winner criteria", nil, prizes)) }
        if let paid = eventDetailsVM.paidRegistrations.first(where: { $0.ownerChildID == ChildManager.shared.selectedChild?.id && $0.isConfirmed }) {
            let amount = (paid.amountPayable ?? paid.amount ?? paid.feeAmount)?.display ?? "Payment confirmed"
            rows.append(("Payment details", amount + " · Paid", ["Payment confirmed through Razorpay", paid.registrationCode, paid.confirmedAt.map { "Confirmed " + EventDateText.range(start: $0, end: nil) }].compactMap { $0 }.joined(separator: "\n")))
        }
        return rows
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        eventDetailsVM.selectedTab == .about ? aboutRows.count : max(1, eventDetailsVM.participants.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventDetailsCardCell.reuseIdentifier, for: indexPath) as? EventDetailsCardCell else { return UITableViewCell() }
        if eventDetailsVM.selectedTab == .about {
            guard aboutRows.indices.contains(indexPath.row) else { return cell }
            let row = aboutRows[indexPath.row]
            cell.configure(heading: row.0, title: row.1, body: row.2)
        } else if eventDetailsVM.participants.indices.contains(indexPath.row) {
            let participant = eventDetailsVM.participants[indexPath.row]
            cell.configure(heading: indexPath.row == 0 ? "Participants" : nil, title: participant.child?.name ?? "Participant", body: participant.status.capitalized)
        } else {
            let message = eventDetailsVM.participantsError ?? (eventDetailsVM.participantsLoading ? "Loading participants…" : "No participants yet. Be the first to join this event.")
            cell.configure(heading: "Participation", title: nil, body: message)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if eventDetailsVM.selectedTab == .about, eventDetailsVM.errorMessage != nil { reloadDetails() }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === heroPager {
            guard heroPager.bounds.width > 0 else { return }
            imagePages.currentPage = Int((heroPager.contentOffset.x / heroPager.bounds.width).rounded())
            return
        }
        guard scrollView === tableView else { return }
        updateCollapsingHeader()
    }
}

extension EventDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { max(1, headerImages.count) }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EventHeroImageCell.reuseIdentifier, for: indexPath) as? EventHeroImageCell else { return UICollectionViewCell() }
        cell.configure(url: headerImages.indices.contains(indexPath.item) ? headerImages[indexPath.item] : nil)
        return cell
    }
}
