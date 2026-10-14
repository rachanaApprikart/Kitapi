import XCTest
@testable import Kitapi

@MainActor final class EventPaymentTests: XCTestCase {
    func testMoneyConversionIsExactAndRejectsInvalidAmounts() throws {
        XCTAssertEqual(try money("999.25").paise(currency: "INR"), 99925)
        XCTAssertThrowsError(try money("0").paise(currency: "INR"))
        XCTAssertThrowsError(try money("1.001").paise(currency: "INR"))
        XCTAssertThrowsError(try money("1").paise(currency: "USD"))
        XCTAssertThrowsError(try money("-1"))
        XCTAssertThrowsError(try money("1abc"))
        XCTAssertThrowsError(try money("9999999999999999999999").paise(currency: "INR"))
    }

    func testGroupLinkOnlyUsesHTTPSWhatsAppAndConfirmedRegistration() throws {
        XCTAssertNil(EventGroupLink.url("https://evil.com/abc"))
        XCTAssertNil(EventGroupLink.url("http://chat.whatsapp.com/abc"))
        XCTAssertNil(EventGroupLink.url("https://chat.whatsapp.com"))
        var record = try EventPaymentMock.record(status: "draft")
        XCTAssertNil(record.groupURL)
        record = try EventPaymentMock.record(status: "confirmed")
        XCTAssertEqual(record.groupURL?.host, "chat.whatsapp.com")
    }

    func testBatchCutoffCapacityAndStatus() throws {
        var batch = EventBatchSummary(id: "b1", startDate: "20-12-2026", seatsAvailable: 0)
        let now = try XCTUnwrap(EventDateText.date("01-11-2026"))
        XCTAssertFalse(batch.acceptsRegistration(at: now))
        batch.seatsAvailable = nil
        XCTAssertTrue(batch.acceptsRegistration(at: now))
        XCTAssertFalse(batch.acceptsRegistration(at: try XCTUnwrap(EventDateText.date("20-12-2026"))))
        batch.isActive = false
        XCTAssertFalse(batch.acceptsRegistration(at: now))
    }

    func testPaidFlowRequiresConsentAndServerConfirmation() async throws {
        let (vm, payment) = await model()
        let withoutConsent = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        XCTAssertNil(withoutConsent)
        XCTAssertEqual(payment.createCalls, 0)
        vm.hasAgreedTerms = true
        let order = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        XCTAssertNotNil(order)
        XCTAssertFalse(vm.isRegistered(childID: "child1"))
        XCTAssertNil(vm.groupURL(childID: "child1"))
        let confirmed = await vm.verifyPayment(proof(), isChildMode: false)
        XCTAssertTrue(confirmed)
        XCTAssertTrue(vm.isRegistered(childID: "child1"))
        XCTAssertNotNil(vm.groupURL(childID: "child1"))
        XCTAssertFalse(vm.isRegistering)
    }

    func testCancelIsRetryableAndDoesNotVerify() async {
        let (vm, payment) = await model()
        vm.hasAgreedTerms = true
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        vm.cancelPayment()
        XCTAssertFalse(vm.isRegistering)
        XCTAssertEqual(payment.verifyCalls, 0)
        XCTAssertFalse(vm.isRegistered(childID: "child1"))
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        XCTAssertEqual(payment.createCalls, 2)
        XCTAssertEqual(vm.activeOrder?.registrationId, "r1")
        vm.cancelPayment()
    }

    func testFailedVerificationRetriesProofWithoutCreatingAnotherOrder() async {
        let (vm, payment) = await model()
        vm.hasAgreedTerms = true
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        payment.failVerify = true
        let first = await vm.verifyPayment(proof(), isChildMode: false)
        XCTAssertFalse(first)
        XCTAssertTrue(vm.hasPendingVerification(childID: "child1"))
        XCTAssertNil(vm.groupURL(childID: "child1"))
        payment.failVerify = false
        let retry = await vm.retryVerification(childID: "child1", isChildMode: false)
        XCTAssertTrue(retry)
        XCTAssertEqual(payment.orderCalls, 1)
        XCTAssertEqual(payment.verifyCalls, 2)
    }

    func testWebhookConfirmationWinsAfterVerificationTimeout() async {
        let (vm, payment) = await model()
        vm.hasAgreedTerms = true
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        payment.failVerify = true
        payment.webhookConfirmed = true
        let confirmed = await vm.verifyPayment(proof(), isChildMode: false)
        XCTAssertTrue(confirmed)
        XCTAssertNotNil(vm.groupURL(childID: "child1"))
    }

    func testWrongOrderAndChildModeNeverVerify() async {
        let (vm, payment) = await model()
        vm.hasAgreedTerms = true
        let childAttempt = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: true, grade: nil, school: nil)
        XCTAssertNil(childAttempt)
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        let confirmed = await vm.verifyPayment(EventPaymentProof(razorpayOrderId: "wrong", razorpayPaymentId: "pay1", razorpaySignature: "sig"), isChildMode: false)
        XCTAssertFalse(confirmed)
        XCTAssertEqual(payment.verifyCalls, 0)
    }

    func testExistingConfirmedRegistrationSkipsCheckout() async {
        let (vm, payment) = await model()
        payment.alreadyConfirmed = true
        vm.hasAgreedTerms = true
        let order = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        XCTAssertNil(order)
        XCTAssertEqual(payment.orderCalls, 0)
        XCTAssertTrue(vm.isRegistered(childID: "child1"))
    }

    func testChildModeChangeRetainsProofForVerificationAfterExit() async {
        let (vm, payment) = await model()
        vm.hasAgreedTerms = true
        _ = await vm.preparePayment(eventID: "e1", childID: "child1", batchID: "b1", isChildMode: false, grade: nil, school: nil)
        let blocked = await vm.verifyPayment(proof(), isChildMode: true)
        XCTAssertFalse(blocked)
        XCTAssertEqual(payment.verifyCalls, 0)
        XCTAssertTrue(vm.hasPendingVerification(childID: "child1"))
        let confirmed = await vm.retryVerification(childID: "child1", isChildMode: false)
        XCTAssertTrue(confirmed)
    }

    func testStartedFreeEventStillLoadsRegisteredGroup() async {
        let service = EventDetailsMockService()
        service.status = "live"
        service.existing = [EventParticipation(id: "p1", childId: "child1", status: "registered", child: nil, whatsappGroupLink: "https://chat.whatsapp.com/free")]
        let vm = EventDetailsViewModel(service: service)
        await vm.load(eventID: "e1")
        XCTAssertTrue(vm.isRegistered(childID: "child1"))
        XCTAssertNotNil(vm.groupURL(childID: "child1"))
        XCTAssertNil(vm.groupURL(childID: "another-child"))
    }

    func testPaymentServiceRequestsAndPaginatedHistoryWithURLProtocol() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EventPaymentURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var logs: [String] = []
        let service = EventPaymentService(network: EventDetailsService(session: session, baseURL: "https://payment.test", tokenProvider: { "test-token" }, logger: { logs.append($0) }))
        let draft = try await service.create(childID: "child1", batchID: "b1", grade: "Grade 3", school: "Little Stars")
        XCTAssertEqual(draft.id, "r1")
        let order = try await service.order(registrationID: draft.id)
        XCTAssertEqual(try order.amount.paise(currency: order.currency), 99925)
        let verified = try await service.verify(registrationID: draft.id, proof: proof())
        XCTAssertTrue(verified.isConfirmed)
        let records = try await service.registrations(eventID: "e1")
        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.allSatisfy { $0.eventId == "e1" })
        let conflict = try await service.create(childID: "duplicate", batchID: "b1", grade: "Grade 3", school: "Little Stars")
        XCTAssertTrue(conflict.isConfirmed)
        XCTAssertTrue(logs.contains { $0.contains("status=409") })
        XCTAssertFalse(logs.contains { $0.contains("test-token") })
        do { _ = try await service.order(registrationID: "../bad"); XCTFail("Unsafe identifier accepted") } catch { }
    }

    func testRegisteredFreeEventShowsGroupFooterAfterStart() async throws {
        let oldChild = ChildManager.shared.selectedChild
        defer { ChildManager.shared.selectedChild = oldChild }
        ChildManager.shared.selectedChild = try JSONDecoder().decode(Child.self, from: Data(#"{"id":"child1","name":"Aadya"}"#.utf8))
        let service = EventDetailsMockService()
        service.status = "live"
        service.existing = [EventParticipation(id: "p1", childId: "child1", status: "registered", child: nil, whatsappGroupLink: "https://chat.whatsapp.com/free")]
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        controller.selectedEvent = try EventDetailsMockService.fixture(status: "live").event
        controller.eventDetailsVM = EventDetailsViewModel(service: service)
        controller.loadViewIfNeeded()
        await controller.eventDetailsVM.load(eventID: "e1")
        await Task.yield()
        controller.render()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.footer.isHidden)
        XCTAssertEqual(controller.bookingButton.title(for: .normal), "Join WhatsApp Group")
        XCTAssertTrue(controller.consentRow?.isHidden == true)
        let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: controller.view.bounds).image { controller.view.layer.render(in: $0.cgContext) })
        attachment.name = "Registered Event WhatsApp Footer"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSuccessCardLayout() {
        let controller = EventRegistrationSuccessViewController()
        controller.amount = "₹999.25"
        controller.joinGroup = {}
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()
        let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: controller.view.bounds).image { controller.view.layer.render(in: $0.cgContext) })
        attachment.name = "Payment Success Card"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSingleBatchUsesSelectedChildWithoutOptionalForm() async throws {
        let oldChild = ChildManager.shared.selectedChild
        let oldMode = ChildManager.shared.isChildMode
        defer {
            ChildManager.shared.selectedChild = oldChild
            ChildManager.shared.isChildMode = oldMode
        }
        ChildManager.shared.isChildMode = false
        ChildManager.shared.selectedChild = try JSONDecoder().decode(Child.self, from: Data(#"{"id":"child1","name":"Aadya"}"#.utf8))
        let (vm, payment) = await model()
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        controller.selectedEvent = try EventDetailsMockService.fixture().event
        controller.eventDetailsVM = vm
        controller.loadViewIfNeeded()
        let checkout = EventCheckoutSpy()
        controller.checkout = checkout
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.isHidden = false
        defer { vm.cancelPayment(); window.isHidden = true; window.rootViewController = nil }
        await Task.yield()
        await Task.yield()
        vm.hasAgreedTerms = true
        controller.chooseBatch()
        XCTAssertNil(controller.presentedViewController)
        for _ in 0..<5 { await Task.yield() }
        XCTAssertEqual(payment.createCalls, 1)
        XCTAssertEqual(payment.requestedChildID, "child1")
        XCTAssertEqual(payment.requestedBatchID, "b1")
        XCTAssertNil(payment.requestedGrade)
        XCTAssertNil(payment.requestedSchool)
        XCTAssertEqual(payment.verifyCalls, 0)
        XCTAssertEqual(checkout.openCalls, 1)
        XCTAssertEqual(checkout.order?.registrationId, "r1")
        XCTAssertNil(controller.presentedViewController)
    }

    func testAgeEligibilityFailureShowsOneErrorMessageWithoutInlineError() async throws {
        let oldChild = ChildManager.shared.selectedChild
        let oldMode = ChildManager.shared.isChildMode
        defer {
            ChildManager.shared.selectedChild = oldChild
            ChildManager.shared.isChildMode = oldMode
        }
        ChildManager.shared.isChildMode = false
        ChildManager.shared.selectedChild = try JSONDecoder().decode(Child.self, from: Data(#"{"id":"child1","name":"Aadya"}"#.utf8))
        let (vm, payment) = await model()
        payment.createError = "Child's age is not eligible for this batch"
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        controller.selectedEvent = try EventDetailsMockService.fixture().event
        controller.eventDetailsVM = vm
        var alerts: [String] = []
        controller.errorPresenter = { alerts.append($0) }
        let checkout = EventCheckoutSpy()
        controller.checkout = checkout
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true; window.rootViewController = nil }
        await Task.yield()
        await Task.yield()
        vm.hasAgreedTerms = true
        controller.chooseBatch()
        for _ in 0..<5 { await Task.yield() }
        XCTAssertEqual(alerts, ["Child's age is not eligible for this batch"])
        XCTAssertEqual(payment.orderCalls, 0)
        XCTAssertEqual(checkout.openCalls, 0)
        XCTAssertFalse(vm.isRegistering)
        XCTAssertNil(vm.registrationError)
        XCTAssertNil(vm.bookingError)
        XCTAssertNotEqual(controller.bookingMessage.text, alerts.first)
        XCTAssertTrue(controller.detailsRetryButton.isHidden)
        controller.render()
        controller.showRegistrationFailureIfNeeded()
        XCTAssertEqual(alerts.count, 1)
    }

    func testRegistrationErrorsAreConsumedOnlyOnce() {
        let vm = EventDetailsViewModel(service: EventDetailsMockService(), paymentService: EventPaymentMock())
        vm.cancelPayment(message: "Payment could not be completed")
        XCTAssertEqual(vm.consumeRegistrationError(), "Payment could not be completed")
        XCTAssertNil(vm.consumeRegistrationError())
        XCTAssertNil(vm.bookingError)
    }

    private func money(_ value: String) throws -> EventMoney { try JSONDecoder().decode(EventMoney.self, from: Data("\"\(value)\"".utf8)) }
    private func proof() -> EventPaymentProof { EventPaymentProof(razorpayOrderId: "order1", razorpayPaymentId: "pay1", razorpaySignature: "sig") }
    private func model() async -> (EventDetailsViewModel, EventPaymentMock) {
        let service = EventDetailsMockService()
        service.paid = true
        let payment = EventPaymentMock()
        let vm = EventDetailsViewModel(service: service, paymentService: payment)
        await vm.load(eventID: "e1")
        return (vm, payment)
    }
}

@MainActor private final class EventCheckoutSpy: EventCheckoutPresenting {
    var openCalls = 0
    var order: EventPaymentOrder?
    func open(order: EventPaymentOrder, controller: UIViewController, completion: @escaping (Result<EventPaymentProof, any Error>) -> Void) throws {
        openCalls += 1
        self.order = order
    }
}

private final class EventPaymentURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "payment.test" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var bytes = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                bytes.append(contentsOf: buffer.prefix(count))
            }
            data = bytes
        }
        let body = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }
        var status = 400
        var payload = #"{"success":false,"message":"Unexpected request"}"#
        let validHeaders = request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token" && request.value(forHTTPHeaderField: "Accept-Language") == "en"
        let record = #"{"id":"r1","childId":"child1","eventId":"e1","eventBatchId":"b1","status":"confirmed","amountPayable":"999.25"}"#
        if validHeaders {
            switch (request.httpMethod, url.path) {
            case ("POST", "/api/event-registrations") where body?["eventBatchId"] == "b1" && body?["hasAgreedConsent"] == "true" && body?["grade"] == "Grade 3" && body?["schoolName"] == "Little Stars":
                let conflict = body?["childId"] == "duplicate"
                status = conflict ? 409 : 201
                payload = "{\"success\":\(conflict ? "false" : "true"),\"data\":\(conflict ? record : record.replacingOccurrences(of: "confirmed", with: "draft"))}"
            case ("POST", "/api/event-registrations/r1/payment-order") where data == nil || data?.isEmpty == true:
                status = 200
                payload = #"{"success":true,"data":{"registrationId":"r1","razorpayOrderId":"order1","keyId":"rzp_test_key","amount":"999.25","currency":"INR"}}"#
            case ("POST", "/api/event-registrations/r1/verify-payment") where body?["razorpayOrderId"] == "order1" && body?["razorpayPaymentId"] == "pay1" && body?["razorpaySignature"] == "sig":
                status = 200
                payload = "{\"success\":true,\"data\":\(record)}"
            case ("GET", "/api/event-registrations/my"):
                let page = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "page" })?.value ?? "1"
                let records = page == "1" ? record + "," + record.replacingOccurrences(of: "e1", with: "other-event") : record.replacingOccurrences(of: "r1", with: "r2")
                status = 200
                payload = "{\"success\":true,\"data\":{\"registrations\":[\(records)],\"pagination\":{\"currentPage\":\(page),\"totalPages\":2,\"totalCount\":3,\"limit\":50}}}"
            default: break
            }
        }
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(payload.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@MainActor final class EventPaymentMock: EventPaymentServing {
    var createCalls = 0
    var orderCalls = 0
    var verifyCalls = 0
    var failVerify = false
    var webhookConfirmed = false
    var alreadyConfirmed = false
    var createError: String?
    var requestedChildID: String?
    var requestedBatchID: String?
    var requestedGrade: String?
    var requestedSchool: String?
    func registrations(eventID: String) async throws -> [EventPaidRegistration] { [] }
    func create(childID: String, batchID: String, grade: String?, school: String?) async throws -> EventPaidRegistration {
        createCalls += 1
        requestedChildID = childID
        requestedBatchID = batchID
        requestedGrade = grade
        requestedSchool = school
        if let createError { throw EventServiceError.server(createError) }
        return try Self.record(status: alreadyConfirmed ? "confirmed" : "draft")
    }
    func order(registrationID: String) async throws -> EventPaymentOrder {
        orderCalls += 1
        return try JSONDecoder().decode(EventPaymentOrder.self, from: Data(#"{"registrationId":"r1","razorpayOrderId":"order1","keyId":"rzp_test_key","amount":"999.25","currency":"INR"}"#.utf8))
    }
    func verify(registrationID: String, proof: EventPaymentProof) async throws -> EventPaidRegistration {
        verifyCalls += 1
        if failVerify { throw URLError(.timedOut) }
        return try Self.record(status: "confirmed")
    }
    func registration(id: String) async throws -> EventPaidRegistration { try Self.record(status: webhookConfirmed ? "confirmed" : "payment_pending") }
    static func record(status: String) throws -> EventPaidRegistration {
        try JSONDecoder().decode(EventPaidRegistration.self, from: Data("{\"id\":\"r1\",\"childId\":\"child1\",\"eventId\":\"e1\",\"eventBatchId\":\"b1\",\"status\":\"\(status)\",\"amountPayable\":\"999.25\",\"event\":{\"id\":\"e1\",\"whatsappGroupLink\":\"https://chat.whatsapp.com/abc\"}}".utf8))
    }
}
