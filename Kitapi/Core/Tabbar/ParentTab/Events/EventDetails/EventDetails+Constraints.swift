//
//  EventDetails+Constraints.swift
//  Kitapi
//
//  Created by Suneel Apprikart on 07/10/26.
//

import UIKit
import Kingfisher
import SafariServices

extension EventDetailsViewController {
    func buildUI() {
        view.backgroundColor = .gradientColor3
        backgroundGradient.colors = [UIColor.gradientColor1.cgColor, UIColor.gradientColor3.cgColor]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 0, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.bottom = 16
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EventDetailsCardCell.self, forCellReuseIdentifier: EventDetailsCardCell.reuseIdentifier)
        tableView.accessibilityIdentifier = "eventDetails.content"
        footer.axis = .vertical
        footer.spacing = 10
        footer.isLayoutMarginsRelativeArrangement = true
        footer.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 12, right: 16)
        footer.backgroundColor = .white
        for subview in [tableView, footer] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: footer.topAnchor),
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        collapsedFooter = footer.heightAnchor.constraint(equalToConstant: 0)
        buildHeader()
        buildBookingFooter()
        buildCollapsingNavigation()
        moreButton.frame = CGRect(x: 0, y: 0, width: 393, height: 48)
        moreButton.setTitleColor(.pinkPrimaryColor, for: .normal)
        moreButton.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 16)
        moreButton.addTarget(self, action: #selector(loadParticipants), for: .touchUpInside)
        loading.hidesWhenStopped = true
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        NSLayoutConstraint.activate([loading.centerXAnchor.constraint(equalTo: view.centerXAnchor), loading.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }

    private func buildHeader() {
        header.backgroundColor = .white
        heroContainer.clipsToBounds = true
        heroPager.backgroundColor = .gradientColor3
        heroPager.isPagingEnabled = true
        heroPager.showsHorizontalScrollIndicator = false
        heroPager.dataSource = self
        heroPager.delegate = self
        heroPager.register(EventHeroImageCell.self, forCellWithReuseIdentifier: EventHeroImageCell.reuseIdentifier)
        heroPager.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(heroPager)
        imagePages.currentPageIndicatorTintColor = .pinkPrimaryColor
        imagePages.pageIndicatorTintColor = .lightGreyColor
        imagePages.isUserInteractionEnabled = false
        imagePages.translatesAutoresizingMaskIntoConstraints = false
        imagePages.isHidden = true
        heroContainer.addSubview(imagePages)
        statusLabel.font = UIFont(name: Fonts.urbanistMedium, size: 13)
        statusLabel.textColor = .white
        statusLabel.layer.cornerRadius = 16
        statusLabel.clipsToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            heroPager.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            heroPager.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            heroPager.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            heroPager.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            heroContainer.heightAnchor.constraint(equalTo: heroContainer.widthAnchor, multiplier: 0.5),
            statusLabel.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -16),
            statusLabel.heightAnchor.constraint(equalToConstant: 32),
            imagePages.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            imagePages.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -4)
        ])
        categoryLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 13)
        categoryLabel.textColor = .textColor
        categoryLabel.numberOfLines = 0
        categoryLabel.lineBreakMode = .byWordWrapping
        categoryPill.layer.cornerRadius = 14
        categoryPill.clipsToBounds = true
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryPill.addSubview(categoryLabel)
        NSLayoutConstraint.activate([
            categoryLabel.leadingAnchor.constraint(equalTo: categoryPill.leadingAnchor, constant: 12),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryPill.trailingAnchor, constant: -12),
            categoryLabel.topAnchor.constraint(equalTo: categoryPill.topAnchor, constant: 6),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryPill.bottomAnchor, constant: -6)
        ])
        categoryLabel.textAlignment = .center
        categoryLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        categoryPillWidth = categoryPill.widthAnchor.constraint(equalToConstant: 24)
        categoryPillWidth?.priority = UILayoutPriority(999)
        categoryPillWidth?.isActive = true
        dateLabel.font = UIFont(name: Fonts.urbanistMedium, size: 12)
        dateLabel.textColor = .textColor
        dateLabel.numberOfLines = 0
        let calendar = UIImageView(image: UIImage(systemName: "calendar"))
        calendar.tintColor = .textColor
        calendar.contentMode = .scaleAspectFit
        calendar.widthAnchor.constraint(equalToConstant: 16).isActive = true
        let dates = UIStackView(arrangedSubviews: [calendar, dateLabel])
        dates.spacing = 6
        dates.alignment = .center
        calendar.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let meta = UIStackView(arrangedSubviews: [categoryPill, dates])
        meta.spacing = 12
        meta.alignment = .center
        categoryPill.widthAnchor.constraint(lessThanOrEqualTo: meta.widthAnchor, multiplier: 0.45).isActive = true
        categoryPill.heightAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        eventTitleLabel.font = UIFont(name: Fonts.urbanistBold, size: 18)
        eventTitleLabel.textColor = .textColor
        eventTitleLabel.numberOfLines = 0
        eventTitleLabel.lineBreakMode = .byWordWrapping
        eventTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: (eventTitleLabel.font?.lineHeight ?? 22) * 2).isActive = true
        let info = UIStackView(arrangedSubviews: [meta, eventTitleLabel])
        info.axis = .vertical
        info.spacing = 16
        info.isLayoutMarginsRelativeArrangement = true
        info.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        tabStack.distribution = .fillProportionally
        for tab in visibleTabs {
            let item = EventFilterTab(title: tab.rawValue) { [weak self] in self?.selectTab(tab) }
            item.button.accessibilityIdentifier = "eventDetails.tab.\(tab.rawValue.lowercased())"
            item.setSelected(tab == .about)
            tabs.append(item)
            tabStack.addArrangedSubview(item)
        }
        tabStack.heightAnchor.constraint(equalToConstant: 68).isActive = true
        let tabRow = UIStackView(arrangedSubviews: [tabStack, UIView()])
        tabRow.isLayoutMarginsRelativeArrangement = true
        tabRow.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let stack = UIStackView(arrangedSubviews: [heroContainer, info, tabRow])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor), stack.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            stack.topAnchor.constraint(equalTo: header.topAnchor), stack.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])
        tableView.tableHeaderView = header
    }

    private func buildCollapsingNavigation() {
        navigationOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationOverlay)
        navigationBack.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        navigationBack.tintColor = .textColor
        navigationBack.backgroundColor = .white
        navigationBack.layer.cornerRadius = 20
        navigationBack.accessibilityLabel = "Back to events"
        navigationBack.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        compactTitle.font = UIFont(name: Fonts.urbanistBold, size: 17)
        compactTitle.textColor = .textColor
        compactTitle.numberOfLines = 2
        compactTitle.lineBreakMode = .byWordWrapping
        compactTitle.alpha = 0
        for subview in [navigationBack, compactTitle] { subview.translatesAutoresizingMaskIntoConstraints = false; navigationOverlay.addSubview(subview) }
        NSLayoutConstraint.activate([
            navigationOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor), navigationOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationOverlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), navigationOverlay.heightAnchor.constraint(equalToConstant: 56),
            navigationBack.leadingAnchor.constraint(equalTo: navigationOverlay.leadingAnchor, constant: 16), navigationBack.centerYAnchor.constraint(equalTo: navigationOverlay.centerYAnchor),
            navigationBack.widthAnchor.constraint(equalToConstant: 40), navigationBack.heightAnchor.constraint(equalToConstant: 40),
            compactTitle.leadingAnchor.constraint(equalTo: navigationBack.trailingAnchor, constant: 12), compactTitle.trailingAnchor.constraint(equalTo: navigationOverlay.trailingAnchor, constant: -16),
            compactTitle.topAnchor.constraint(equalTo: navigationOverlay.topAnchor, constant: 6), compactTitle.bottomAnchor.constraint(equalTo: navigationOverlay.bottomAnchor, constant: -6)
        ])
    }

    private func buildBookingFooter() {
        bookingMessage.font = UIFont(name: Fonts.urbanistMedium, size: 13)
        bookingMessage.textColor = .labelPlaceholderColor
        bookingMessage.numberOfLines = 0
        consentButton.tintColor = .pinkPrimaryColor
        consentButton.accessibilityLabel = "Accept Terms, Privacy and Media Policy"
        consentButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        let consentHeight = consentButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        consentHeight.priority = .defaultHigh
        consentHeight.isActive = true
        consentButton.addTarget(self, action: #selector(toggleConsent), for: .touchUpInside)
        let policies = UITextView()
        policies.isEditable = false
        policies.isScrollEnabled = false
        policies.backgroundColor = .clear
        policies.textContainerInset = .zero
        policies.textContainer.lineFragmentPadding = 0
        policies.delegate = self
        let text = NSMutableAttributedString(string: "I accept the ", attributes: [.font: UIFont(name: Fonts.urbanistRegular, size: 14) ?? .systemFont(ofSize: 14), .foregroundColor: UIColor.textColor])
        for (index, value) in [("Terms", APPConstants.eventTermsURL), ("Privacy", APPConstants.eventPrivacyURL), ("Media Policy", APPConstants.eventMediaPolicyURL)].enumerated() {
            if index > 0 { text.append(NSAttributedString(string: index == 2 ? " & " : ", ")) }
            text.append(NSAttributedString(string: value.0, attributes: [.link: value.1, .font: UIFont(name: Fonts.urbanistSemiBold, size: 14) ?? .systemFont(ofSize: 14)]))
        }
        policies.attributedText = text
        policies.linkTextAttributes = [.foregroundColor: UIColor.pinkPrimaryColor, .underlineStyle: NSUnderlineStyle.single.rawValue]
        let consentRow = UIStackView(arrangedSubviews: [consentButton, policies])
        self.consentRow = consentRow
        consentRow.spacing = 8
        consentRow.alignment = .center
        bookingButton.backgroundColor = .pinkPrimaryColor
        bookingButton.setTitleColor(.white, for: .normal)
        bookingButton.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 17)
        bookingButton.layer.cornerRadius = 24
        let bookingHeight = bookingButton.heightAnchor.constraint(equalToConstant: 48)
        bookingHeight.priority = .defaultHigh
        bookingHeight.isActive = true
        bookingButton.accessibilityIdentifier = "eventDetails.participate"
        bookingButton.addTarget(self, action: #selector(participate), for: .touchUpInside)
        footer.addArrangedSubview(bookingMessage)
        detailsRetryButton.setTitle("Try Again", for: .normal)
        detailsRetryButton.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 14)
        detailsRetryButton.tintColor = .pinkPrimaryColor
        detailsRetryButton.addTarget(self, action: #selector(reloadDetails), for: .touchUpInside)
        footer.addArrangedSubview(detailsRetryButton)
        footer.addArrangedSubview(consentRow)
        footer.addArrangedSubview(bookingButton)
    }

}

extension EventDetailsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        openPolicy(URL.absoluteString, fallback: APPConstants.eventTermsURL)
        return false
    }
}

