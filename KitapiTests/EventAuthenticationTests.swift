import XCTest
import UIKit
@testable import Kitapi

@MainActor
final class EventAuthenticationTests: XCTestCase {
    func testListAuthenticationFailureStopsLoadingWithoutInlineErrorOrAutoRetry() async {
        let service = AuthListing()
        let vm = EventListViewModel(service: service)
        await vm.reload()
        XCTAssertTrue(vm.requiresSignIn)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.canLoadMore)
        await vm.loadNextPage()
        XCTAssertEqual(service.calls, 1)
    }

    func testReadAuthenticationFailuresAreHandledCentrallyAtEveryStage() async {
        for stage in [Stage.details, .batches, .freeHistory, .paidHistory, .participants] {
            let service = AuthDetails()
            let payment = AuthPayment()
            service.paid = stage == .paidHistory
            service.failure = stage
            payment.failure = stage
            let vm = EventDetailsViewModel(service: service, paymentService: payment)
            await vm.load(eventID: "e1")
            if stage == .participants { await vm.loadParticipants(eventID: "e1") }
            assertAuthenticationOnly(vm)
            XCTAssertFalse(vm.isLoading)
            XCTAssertFalse(vm.participantsLoading)
            XCTAssertFalse(vm.canLoadParticipants)
            if stage == .details { XCTAssertEqual(service.batchCalls, 0) }
        }
    }

    func testFreeRegistration401DoesNotReconcileOrPublishBanner() async {
        let service = AuthDetails()
        let vm = EventDetailsViewModel(service: service, paymentService: AuthPayment())
        await vm.load(eventID: "e1")
        service.failure = .freeRegistration
        vm.hasAgreedTerms = true
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        assertAuthenticationOnly(vm)
        XCTAssertFalse(vm.isRegistering)
        XCTAssertEqual(service.historyCalls, 1)
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 1)
    }

    func testPaidCreateAndOrder401DoNotReconcileOrPublishBanner() async {
        for stage in [Stage.create, .order] {
            let (vm, payment) = await paidModel()
            payment.failure = stage
            vm.hasAgreedTerms = true
            let order = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
            XCTAssertNil(order)
            assertAuthenticationOnly(vm)
            XCTAssertFalse(vm.isRegistering)
            XCTAssertNil(vm.activeOrder)
            XCTAssertEqual(payment.detailCalls, 0)
            XCTAssertEqual(payment.orderCalls, stage == .create ? 0 : 1)
        }
    }

    func testVerification401DoesNotReconcileAndClearsSessionBoundProof() async {
        let (vm, payment) = await paidModel()
        vm.hasAgreedTerms = true
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        payment.failure = .verify
        let confirmed = await vm.verifyPayment(proof, isChildMode: false)
        XCTAssertFalse(confirmed)
        assertAuthenticationOnly(vm)
        XCTAssertFalse(vm.isRegistering)
        XCTAssertFalse(vm.hasPendingVerification(childID: "child1"))
        XCTAssertEqual(payment.detailCalls, 0)
        let retried = await vm.retryVerification(childID: "child1", isChildMode: false)
        XCTAssertFalse(retried)
        XCTAssertEqual(payment.verifyCalls, 1)
        vm.cancelPayment(message: "Late checkout callback")
        XCTAssertNil(vm.consumeRegistrationError())
    }

    func testAuthenticationFailureDuringReconciliationSuppressesOriginalError() async {
        let service = AuthDetails()
        let free = EventDetailsViewModel(service: service, paymentService: AuthPayment())
        await free.load(eventID: "e1")
        service.failure = .freeReconciliation
        free.hasAgreedTerms = true
        await free.register(eventID: "e1", childID: "child1", isChildMode: false)
        assertAuthenticationOnly(free)
        XCTAssertEqual(service.historyCalls, 2)

        for stage in [Stage.orderReconciliation, .verificationReconciliation] {
            let (vm, payment) = await paidModel()
            vm.hasAgreedTerms = true
            payment.failure = stage
            let order = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
            if stage == .verificationReconciliation {
                XCTAssertNotNil(order)
                let confirmed = await vm.verifyPayment(proof, isChildMode: false)
                XCTAssertFalse(confirmed)
            }
            assertAuthenticationOnly(vm)
            XCTAssertEqual(payment.detailCalls, 1)
            XCTAssertFalse(vm.isRegistering)
        }
    }

    func testPermissionErrorStillShowsReadableFailureWithoutSessionExpiration() async {
        let (vm, payment) = await paidModel()
        payment.failure = .create
        payment.error = EventServiceError.server("Exit child mode to register")
        vm.hasAgreedTerms = true
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        XCTAssertFalse(vm.requiresSignIn)
        XCTAssertFalse(vm.isRegistering)
        XCTAssertEqual(vm.consumeRegistrationError(), "Exit child mode to register")
    }

    func testDetailsAuthenticationHidesBookingActionsWithoutShowingBanner() async throws {
        let service = AuthDetails()
        service.failure = .details
        let vm = EventDetailsViewModel(service: service, paymentService: AuthPayment())
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        controller.selectedEvent = try EventDetailsMockService.fixture().event
        controller.eventDetailsVM = vm
        var alerts: [String] = []
        controller.errorPresenter = { alerts.append($0) }
        controller.loadViewIfNeeded()
        await Task.yield()
        await Task.yield()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()
        controller.showRegistrationFailureIfNeeded()
        XCTAssertTrue(vm.requiresSignIn)
        XCTAssertTrue(controller.footer.isHidden)
        XCTAssertFalse(controller.bookingButton.isEnabled)
        XCTAssertTrue(alerts.isEmpty)
    }

    private var proof: EventPaymentProof { EventPaymentProof(razorpayOrderId: "order1", razorpayPaymentId: "pay1", razorpaySignature: "sig") }

    private func paidModel() async -> (EventDetailsViewModel, AuthPayment) {
        let service = AuthDetails()
        service.paid = true
        let payment = AuthPayment()
        let vm = EventDetailsViewModel(service: service, paymentService: payment)
        await vm.load(eventID: "e1")
        return (vm, payment)
    }

    private func assertAuthenticationOnly(_ vm: EventDetailsViewModel, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(vm.requiresSignIn, file: file, line: line)
        XCTAssertFalse(vm.registrationChecked, file: file, line: line)
        XCTAssertNil(vm.errorMessage, file: file, line: line)
        XCTAssertNil(vm.bookingError, file: file, line: line)
        XCTAssertNil(vm.participantsError, file: file, line: line)
        XCTAssertNil(vm.consumeRegistrationError(), file: file, line: line)
        XCTAssertNil(vm.groupURL(childID: "child1"), file: file, line: line)
    }
}

private enum Stage { case details, batches, freeHistory, paidHistory, participants, freeRegistration, create, order, verify, freeReconciliation, orderReconciliation, verificationReconciliation }

@MainActor private final class AuthListing: EventListing {
    var calls = 0
    func fetchEvents(filter: EventListFilter, page: Int) async throws -> EventPage {
        calls += 1
        throw EventServiceError.signInRequired
    }
}

@MainActor private final class AuthDetails: EventDetailsServing {
    var failure: Stage?
    var paid = false
    var batchCalls = 0
    var historyCalls = 0
    var registrationCalls = 0
    func details(eventID: String) async throws -> EventDetails {
        if failure == .details { throw EventServiceError.signInRequired }
        return try EventDetailsMockService.fixture(id: eventID)
    }
    func batches(eventID: String) async throws -> [EventBatchSummary] {
        batchCalls += 1
        if failure == .batches { throw EventServiceError.signInRequired }
        return paid ? [EventBatchSummary(id: "b1")] : []
    }
    func participants(eventID: String, page: Int) async throws -> EventParticipantPage {
        throw EventServiceError.signInRequired
    }
    func myParticipations(eventID: String) async throws -> [EventParticipation] {
        historyCalls += 1
        if failure == .freeHistory || failure == .freeReconciliation { throw EventServiceError.signInRequired }
        return []
    }
    func registerFree(eventID: String, childID: String) async throws -> EventParticipation {
        registrationCalls += 1
        if failure == .freeReconciliation { throw URLError(.timedOut) }
        throw EventServiceError.signInRequired
    }
}

@MainActor private final class AuthPayment: EventPaymentServing {
    var failure: Stage?
    var error: any Error = EventServiceError.signInRequired
    var orderCalls = 0
    var verifyCalls = 0
    var detailCalls = 0
    func registrations(eventID: String) async throws -> [EventPaidRegistration] {
        if failure == .paidHistory { throw error }
        return []
    }
    func create(childID: String, batchID: String, grade: String?, school: String?) async throws -> EventPaidRegistration {
        if failure == .create { throw error }
        return try EventPaymentMock.record(status: "draft")
    }
    func order(registrationID: String) async throws -> EventPaymentOrder {
        orderCalls += 1
        if failure == .order { throw error }
        if failure == .orderReconciliation { throw URLError(.timedOut) }
        return try await EventPaymentMock().order(registrationID: registrationID)
    }
    func verify(registrationID: String, proof: EventPaymentProof) async throws -> EventPaidRegistration {
        verifyCalls += 1
        if failure == .verificationReconciliation { throw URLError(.timedOut) }
        throw error
    }
    func registration(id: String) async throws -> EventPaidRegistration {
        detailCalls += 1
        throw error
    }
}
