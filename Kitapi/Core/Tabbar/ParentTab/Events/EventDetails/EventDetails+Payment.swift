import UIKit

extension EventDetailsViewController {
    func retryPaymentVerification() {
        Task { [weak self] in
            guard let self else { return }
            if await self.eventDetailsVM.retryVerification(childID: ChildManager.shared.selectedChild?.id, isChildMode: ChildManager.shared.isChildMode) { self.paymentSuccessful(amount: nil) }
            self.showRegistrationFailureIfNeeded()
        }
    }
    func openGroup() {
        guard !ChildManager.shared.isChildMode, let url = eventDetailsVM.groupURL(childID: ChildManager.shared.selectedChild?.id) else { return }
        UIApplication.shared.open(url, options: [:]) { [weak self] opened in
            if !opened { Task { @MainActor in self?.showPaymentMessage(title: "Unable to open WhatsApp", message: "Please try again later.") } }
        }
    }

    func chooseBatch() {
        guard eventDetailsVM.hasAgreedTerms, !ChildManager.shared.isChildMode, let childID = ChildManager.shared.selectedChild?.id else { return }
        let available = eventDetailsVM.batches.filter { $0.acceptsRegistration(at: Date()) }
        guard !available.isEmpty else { showPaymentMessage(title: "Registration unavailable", message: "No batches are available for booking."); return }
        if available.count == 1, let batch = available.first { prepareRegistration(batch: batch, childID: childID); return }
        let sheet = UIAlertController(title: "Choose a batch", message: "Register \(ChildManager.shared.selectedChild?.name ?? "your child")", preferredStyle: .actionSheet)
        for batch in available {
            let amount = batch.feeAmount?.display ?? eventDetailsVM.details?.feeAmount.map { "₹\(NSDecimalNumber(decimal: $0).stringValue)" } ?? ""
            sheet.addAction(UIAlertAction(title: "\(batch.name ?? "Batch") \(amount)", style: .default) { [weak self] _ in self?.prepareRegistration(batch: batch, childID: childID) })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = bookingButton
        sheet.popoverPresentationController?.sourceRect = bookingButton.bounds
        present(sheet, animated: true)
    }

    func prepareRegistration(batch: EventBatchSummary, childID: String) {
        guard let eventID = eventId, ChildManager.shared.selectedChild?.id == childID else { return }
        Task { [weak self] in
            guard let self else { return }
            let order = await self.eventDetailsVM.preparePayment(eventID: eventID, childID: childID, batchID: batch.id, isChildMode: ChildManager.shared.isChildMode, grade: nil, school: nil)
            if let order { self.startCheckout(order, batch: batch, childID: childID) }
            else if self.eventDetailsVM.isRegistered(childID: childID) { self.paymentSuccessful(amount: nil) }
            self.showRegistrationFailureIfNeeded()
        }
    }

    private func startCheckout(_ order: EventPaymentOrder, batch: EventBatchSummary, childID: String) {
        guard view.window != nil, ChildManager.shared.selectedChild?.id == childID, !ChildManager.shared.isChildMode,
              eventDetailsVM.details?.acceptsRegistration == true, batch.acceptsRegistration(at: Date()) else { eventDetailsVM.cancelPayment(); return }
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in self?.startCheckout(order, batch: batch, childID: childID) }
            return
        }
        do {
            try checkout.open(order: order, controller: self) { [weak self] result in
                guard let self else { return }
                switch result {
                case .failure(let error):
                    self.eventDetailsVM.cancelPayment(message: error.localizedDescription)
                    self.showRegistrationFailureIfNeeded()
                case .success(let proof):
                    Task { [weak self] in
                        guard let self else { return }
                        let confirmed = await self.eventDetailsVM.verifyPayment(proof, isChildMode: ChildManager.shared.isChildMode)
                        if confirmed, self.view.window != nil { self.paymentSuccessful(amount: order.amount.display) }
                        self.showRegistrationFailureIfNeeded()
                    }
                }
            }
        } catch {
            eventDetailsVM.cancelPayment(message: error.localizedDescription)
            showRegistrationFailureIfNeeded()
        }
    }

    private func paymentSuccessful(amount: String?) {
        let alert = EventRegistrationSuccessViewController()
        alert.amount = amount
        alert.modalPresentationStyle = .overFullScreen
        alert.modalTransitionStyle = UIAccessibility.isReduceMotionEnabled ? .coverVertical : .crossDissolve
        if eventDetailsVM.groupURL(childID: ChildManager.shared.selectedChild?.id) != nil {
            alert.joinGroup = { [weak self] in self?.openGroup() }
        }
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in self?.present(alert, animated: true) }
        } else { present(alert, animated: true) }
    }

    private func showPaymentMessage(title: String, message: String) {
        errorPresenter(message)
    }

    func showRegistrationFailureIfNeeded() {
        guard let message = eventDetailsVM.consumeRegistrationError(), viewIfLoaded?.window != nil else { return }
        errorPresenter(message)
    }
}
