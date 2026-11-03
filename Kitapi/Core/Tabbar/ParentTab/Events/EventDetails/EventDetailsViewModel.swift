import Foundation

enum EventDetailsTab: String, CaseIterable { case about = "About", participation = "Participation" }

@MainActor
final class EventDetailsViewModel {
    private let service: any EventDetailsServing
    private let paymentService: any EventPaymentServing
    private(set) var batches: [EventBatchSummary] = []
    private(set) var paidRegistrations: [EventPaidRegistration] = []
    private(set) var activeOrder: EventPaymentOrder?
    private var checkoutChildID: String?
    private var pendingVerification: (order: EventPaymentOrder, proof: EventPaymentProof, childID: String)?
    func hasPendingVerification(childID: String?) -> Bool { childID != nil && pendingVerification?.childID == childID }
    private var generation = UUID()
    private var participantPage = 0
    private var participantTotalPages = 1
    private(set) var details: EventDetails?
    private(set) var bookingKind: EventBookingKind = .unknown
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var bookingError: String?
    private(set) var registrationError: String?

    func consumeRegistrationError() -> String? {
        defer { registrationError = nil }
        return registrationError
    }
    private(set) var participants: [EventParticipation] = []
    private(set) var participantsLoading = false
    private(set) var participantsError: String?
    private(set) var myParticipations: [EventParticipation] = []
    private(set) var isRegistering = false
    private(set) var registrationChecked = false
    private(set) var requiresSignIn = false
    var hasAgreedTerms = false
    var selectedTab: EventDetailsTab = .about
    var onChange: (() -> Void)?
    var canLoadParticipants: Bool { !requiresSignIn && !participantsLoading && participantPage < participantTotalPages }

    init(service: (any EventDetailsServing)? = nil, paymentService: (any EventPaymentServing)? = nil) {
        self.service = service ?? EventDetailsService()
        self.paymentService = paymentService ?? EventPaymentService()
    }
    nonisolated deinit {}

    func load(eventID: String) async {
        guard !isRegistering else { return }
        let token = UUID()
        generation = token
        isLoading = true
        details = nil
        bookingKind = .unknown
        hasAgreedTerms = false
        errorMessage = nil
        bookingError = nil
        registrationError = nil
        myParticipations = []
        paidRegistrations = []
        batches = []
        registrationChecked = false
        requiresSignIn = false
        participants = []
        participantPage = 0
        participantTotalPages = 1
        participantsLoading = false
        participantsError = nil
        onChange?()
        defer { if generation == token { isLoading = false; onChange?() } }
        do {
            let result = try await service.details(eventID: eventID)
            guard generation == token, !Task.isCancelled else { return }
            details = result
            onChange?()
            do {
                let batches = try await service.batches(eventID: eventID)
                guard generation == token, !Task.isCancelled else { return }
                self.batches = batches
                bookingKind = !batches.isEmpty || (result.feeAmount ?? 0) > 0 ? .paid : .free
                if bookingKind == .free {
                    let existing = try await service.myParticipations(eventID: eventID)
                    guard generation == token, !Task.isCancelled else { return }
                    myParticipations = existing
                    registrationChecked = true
                } else {
                    let existing = try await paymentService.registrations(eventID: eventID)
                    guard generation == token, !Task.isCancelled else { return }
                    paidRegistrations = existing
                    registrationChecked = true
                }
            } catch EventServiceError.signInRequired {
                guard generation == token, !Task.isCancelled else { return }
                markRequiresSignIn()
            } catch {
                guard generation == token, !Task.isCancelled else { return }
                bookingError = error.localizedDescription
            }
        } catch EventServiceError.signInRequired {
            guard generation == token, !Task.isCancelled else { return }
            markRequiresSignIn()
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func loadParticipants(eventID: String) async {
        guard canLoadParticipants else { return }
        let token = generation
        participantsLoading = true
        participantsError = nil
        onChange?()
        defer { if generation == token { participantsLoading = false; onChange?() } }
        do {
            let result = try await service.participants(eventID: eventID, page: participantPage + 1)
            guard generation == token, !Task.isCancelled else { return }
            guard result.pagination.currentPage == participantPage + 1 else { throw EventServiceError.invalidResponse }
            var seen = Set(participants.map(\.id))
            participants += result.participants.filter { seen.insert($0.id).inserted }
            participantPage += 1
            participantTotalPages = result.participants.isEmpty ? participantPage : max(participantPage, result.pagination.totalPages)
        } catch EventServiceError.signInRequired {
            guard generation == token, !Task.isCancelled else { return }
            markRequiresSignIn()
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            participantsError = error.localizedDescription
        }
    }

    func isRegistered(childID: String?) -> Bool {
        guard let childID else { return false }
        return myParticipations.contains { $0.childId == childID && $0.isRegistered } || paidRegistrations.contains { $0.ownerChildID == childID && $0.isConfirmed }
    }

    func groupURL(childID: String?) -> URL? {
        guard !requiresSignIn, let childID else { return nil }
        if let paid = paidRegistrations.first(where: { $0.ownerChildID == childID && $0.isConfirmed }) { return paid.groupURL }
        guard let free = myParticipations.first(where: { $0.childId == childID && $0.isRegistered }) else { return nil }
        return EventGroupLink.url(free.whatsappGroupLink ?? free.event?.whatsappGroupLink ?? details?.whatsappGroupLink)
    }

    func preparePayment(eventID: String, childID: String?, batchID: String, isChildMode: Bool, grade: String?, school: String?) async -> EventPaymentOrder? {
        guard !requiresSignIn, !isRegistering, !isLoading, registrationChecked, bookingKind == .paid,
              details?.event.id == eventID, details?.acceptsRegistration == true,
              hasAgreedTerms, !isChildMode, let childID, !childID.isEmpty,
              batches.contains(where: { $0.id == batchID && $0.acceptsRegistration(at: Date()) }) else { return nil }
        isRegistering = true
        registrationError = nil
        onChange?()
        do {
            var record = try await paymentService.create(childID: childID, batchID: batchID, grade: grade, school: school)
            guard record.ownerChildID == nil || record.ownerChildID == childID,
                  (record.eventId ?? record.event?.id).map({ $0 == eventID }) ?? true,
                  (record.eventBatchId ?? record.batch?.id).map({ $0 == batchID }) ?? true else { throw EventServiceError.invalidResponse }
            record.childId = childID
            store(record)
            if record.isConfirmed { isRegistering = false; onChange?(); return nil }
            checkoutChildID = childID
            let order = try await paymentService.order(registrationID: record.id)
            guard order.registrationId == record.id, !order.keyId.isEmpty, !order.razorpayOrderId.isEmpty else { throw EventServiceError.invalidResponse }
            _ = try order.amount.paise(currency: order.currency)
            activeOrder = order
            onChange?()
            return order
        } catch EventServiceError.signInRequired {
            markRequiresSignIn()
            finishCheckout()
            return nil
        } catch {
            registrationError = error.localizedDescription
            // The webhook can confirm while an order request is in flight.
            if let record = paidRegistrations.first(where: { $0.ownerChildID == childID && ($0.eventBatchId ?? $0.batch?.id) == batchID }) {
                do {
                    var updated = try await paymentService.registration(id: record.id)
                    if updated.id == record.id, updated.isConfirmed, updated.ownerChildID == nil || updated.ownerChildID == childID {
                        updated.childId = childID
                        store(updated)
                        registrationError = nil
                    }
                } catch EventServiceError.signInRequired { markRequiresSignIn() }
                catch { /* Keep the original payment error when reconciliation also fails. */ }
            }
            finishCheckout()
            return nil
        }
    }

    func verifyPayment(_ proof: EventPaymentProof, isChildMode: Bool) async -> Bool {
        guard !requiresSignIn else { return false }
        guard isRegistering, let order = activeOrder, proof.razorpayOrderId == order.razorpayOrderId,
              !proof.razorpayPaymentId.isEmpty, !proof.razorpaySignature.isEmpty else {
            registrationError = "Payment could not be verified. Check your registration before trying again."
            finishCheckout(); return false
        }
        if let checkoutChildID { pendingVerification = (order, proof, checkoutChildID) }
        defer { finishCheckout() }
        guard !isChildMode else { registrationError = "Exit child mode to verify payment."; return false }
        do {
            var result = try await paymentService.verify(registrationID: order.registrationId, proof: proof)
            guard result.id == order.registrationId, result.ownerChildID == nil || result.ownerChildID == checkoutChildID else { throw EventServiceError.invalidResponse }
            result.childId = checkoutChildID
            store(result)
            guard result.isConfirmed else { throw EventServiceError.server("Payment confirmation is pending. Please refresh before paying again.") }
            pendingVerification = nil
            return true
        } catch EventServiceError.signInRequired {
            markRequiresSignIn()
            return false
        } catch {
            registrationError = error.localizedDescription
            do {
                var result = try await paymentService.registration(id: order.registrationId)
                if result.id == order.registrationId, result.isConfirmed, result.ownerChildID == nil || result.ownerChildID == checkoutChildID {
                    result.childId = checkoutChildID
                    store(result)
                    pendingVerification = nil
                    registrationError = nil
                    return true
                }
            } catch EventServiceError.signInRequired { markRequiresSignIn() }
            catch { /* Keep the original verification error when reconciliation also fails. */ }
            return false
        }
    }

    func retryVerification(childID: String?, isChildMode: Bool) async -> Bool {
        guard !requiresSignIn, !isRegistering, !isChildMode, let pendingVerification, pendingVerification.childID == childID else { return false }
        activeOrder = pendingVerification.order
        checkoutChildID = pendingVerification.childID
        isRegistering = true
        registrationError = nil
        onChange?()
        return await verifyPayment(pendingVerification.proof, isChildMode: isChildMode)
    }

    func cancelPayment(message: String = "Your registration is not confirmed yet. You can continue payment.") {
        guard !requiresSignIn else { finishCheckout(); return }
        registrationError = message
        finishCheckout()
    }

    private func finishCheckout() {
        activeOrder = nil
        checkoutChildID = nil
        isRegistering = false
        onChange?()
    }

    private func store(_ record: EventPaidRegistration) {
        paidRegistrations.removeAll { $0.id == record.id }
        paidRegistrations.append(record)
    }

    private func markRequiresSignIn() {
        requiresSignIn = true
        registrationChecked = false
        hasAgreedTerms = false
        errorMessage = nil
        bookingError = nil
        registrationError = nil
        participantsError = nil
        pendingVerification = nil
    }

    func register(eventID: String, childID: String?, isChildMode: Bool) async {
        guard !requiresSignIn, !isRegistering else { return }
        registrationError = nil
        guard !isLoading, let details, details.event.id == eventID, details.acceptsRegistration, bookingKind == .free, registrationChecked else {
            registrationError = "Registration is not available for this event."; onChange?(); return
        }
        guard !isChildMode else { registrationError = "Exit child mode to register."; onChange?(); return }
        guard let childID, !childID.isEmpty else { registrationError = "Select a child before registering."; onChange?(); return }
        guard !isRegistered(childID: childID) else { registrationError = "This child is already registered."; onChange?(); return }
        guard hasAgreedTerms else { registrationError = "Please accept the Terms, Privacy & Media Policy."; onChange?(); return }
        isRegistering = true
        onChange?()
        defer { isRegistering = false; onChange?() }
        do {
            let result = try await service.registerFree(eventID: eventID, childID: childID)
            myParticipations.append(result)
        } catch EventServiceError.signInRequired {
            markRequiresSignIn()
        } catch {
            // A timeout/duplicate error can occur after the backend committed. Reconcile before retrying.
            do { myParticipations = try await service.myParticipations(eventID: eventID) }
            catch EventServiceError.signInRequired { markRequiresSignIn(); return }
            catch { /* Keep the original registration error when reconciliation also fails. */ }
            if !isRegistered(childID: childID) { registrationError = error.localizedDescription }
        }
    }
}
