import XCTest
import UIKit
@testable import Kitapi

@MainActor
final class EventDetailsTests: XCTestCase {
    func testDetailDecodingSupportsStepsFeesAndMultipleImages() throws {
        let details = try EventDetailsMockService.fixture()
        XCTAssertEqual(details.instructions.count, 2)
        XCTAssertEqual(details.instructions.map(\.step), [1, 2])
        XCTAssertEqual(details.feeAmount, 0)
        XCTAssertEqual(details.images.count, 2)
        let arrayImage = try JSONDecoder().decode(EventImage.self, from: Data("[\"https://example.com/1.png\",{\"url\":\"https://example.com/2.png\"}]".utf8))
        XCTAssertEqual(arrayImage.url, "https://example.com/1.png")
    }

    func testRegistrationStopsAtStartOrDeadlineAndForLiveEvents() throws {
        let details = try EventDetailsMockService.fixture()
        let before = try XCTUnwrap(EventDateText.date("01-11-2026"))
        let start = try XCTUnwrap(EventDateText.date("20-12-2026"))
        XCTAssertTrue(details.acceptsRegistration(at: before))
        XCTAssertFalse(details.acceptsRegistration(at: start))
        XCTAssertFalse(try EventDetailsMockService.fixture(status: "live").acceptsRegistration(at: before))
        XCTAssertFalse(try EventDetailsMockService.fixture(status: "completed").acceptsRegistration(at: before))
        XCTAssertFalse(details.acceptsRegistration(at: try XCTUnwrap(EventDateText.date("19-12-2026"))))
    }

    func testLegalLinksUseProvidedHTTPSURLs() {
        XCTAssertEqual(EventLegalLinks.url(apiValue: APPConstants.eventTermsURL, configurationKey: "")?.path, "/termsAndConditions")
        XCTAssertEqual(EventLegalLinks.url(apiValue: APPConstants.eventPrivacyURL, configurationKey: "")?.path, "/privacyPolicy")
        XCTAssertNil(EventLegalLinks.url(apiValue: "javascript:alert(1)", configurationKey: ""))
    }

    func testFreeRegistrationRequiresConsentAndCannotDuplicate() async {
        let service = EventDetailsMockService()
        let vm = EventDetailsViewModel(service: service)
        await vm.load(eventID: "e1")
        XCTAssertEqual(vm.bookingKind, .free)
        XCTAssertTrue(vm.registrationChecked)
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 0)
        XCTAssertNotNil(vm.registrationError)
        vm.hasAgreedTerms = true
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 1)
        XCTAssertTrue(vm.isRegistered(childID: "child1"))
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 1)
    }

    func testPaidAndUnknownClassificationNeverUseFreeAPI() async {
        let service = EventDetailsMockService()
        service.paid = true
        let vm = EventDetailsViewModel(service: service, paymentService: EventPaymentMock())
        await vm.load(eventID: "e1")
        XCTAssertEqual(vm.bookingKind, .paid)
        vm.hasAgreedTerms = true
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 0)
        service.failBatches = true
        await vm.load(eventID: "e1")
        XCTAssertEqual(vm.bookingKind, .unknown)
        vm.hasAgreedTerms = true
        await vm.register(eventID: "e1", childID: "child1", isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 0)
    }

    func testChildModeAndMissingChildAreBlocked() async {
        let service = EventDetailsMockService()
        let vm = EventDetailsViewModel(service: service)
        await vm.load(eventID: "e1")
        vm.hasAgreedTerms = true
        await vm.register(eventID: "e1", childID: "child1", isChildMode: true)
        await vm.register(eventID: "e1", childID: nil, isChildMode: false)
        XCTAssertEqual(service.registrationCalls, 0)
    }

    func testParticipantsEmptyAndPaginationRetry() async {
        let service = EventDetailsMockService()
        let vm = EventDetailsViewModel(service: service)
        await vm.load(eventID: "e1")
        service.failParticipants = true
        await vm.loadParticipants(eventID: "e1")
        XCTAssertNotNil(vm.participantsError)
        XCTAssertTrue(vm.canLoadParticipants)
        service.failParticipants = false
        await vm.loadParticipants(eventID: "e1")
        XCTAssertTrue(vm.participants.isEmpty)
        XCTAssertNil(vm.participantsError)
        XCTAssertFalse(vm.canLoadParticipants)
    }

    func testFreeRegistrationRequestUsesStringConsentAndLogsResponse() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [EventDetailsURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        var logs: [String] = []
        let service = EventDetailsService(session: session, baseURL: "https://details.test", tokenProvider: { "test-secret" }, logger: { logs.append($0) })
        let result = try await service.registerFree(eventID: "e1", childID: "child1")
        XCTAssertEqual(result.childId, "child1")
        XCTAssertTrue(logs.contains { $0.contains("POST /api/events/parent/e1/register") })
        XCTAssertTrue(logs.contains { $0.contains("SUCCESS") })
        XCTAssertFalse(logs.contains { $0.contains("test-secret") })
        do { _ = try await service.details(eventID: "../bad"); XCTFail("Invalid path accepted") } catch { }
    }

    func testDetailsLayoutAndCollapsingHeader() async throws {
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        let service = EventDetailsMockService()
        controller.selectedEvent = try EventDetailsMockService.fixture().event
        controller.eventDetailsVM = EventDetailsViewModel(service: service)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        await Task.yield()
        await Task.yield()
        controller.view.layoutIfNeeded()
        XCTAssertEqual(controller.tabs.count, 1)
        XCTAssertEqual(String(try XCTUnwrap(controller.tabs.first?.button.configuration?.attributedTitle).characters), "About")
        XCTAssertEqual(controller.tableView.numberOfRows(inSection: 0), 4)
        XCTAssertGreaterThan(controller.header.frame.height, 250)
        XCTAssertEqual(controller.imagePages.numberOfPages, 2)
        XCTAssertEqual(controller.compactTitle.alpha, 0)
        XCTAssertEqual(controller.compactTitle.numberOfLines, 2)
        XCTAssertEqual(controller.compactTitle.bounds.height, 44, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(controller.eventTitleLabel.bounds.height, controller.eventTitleLabel.font.lineHeight * 2 - 0.5)
        XCTAssertEqual(controller.heroContainer.bounds.height - controller.statusLabel.frame.maxY, 16, accuracy: 0.5)
        XCTAssertEqual(controller.heroContainer.bounds.width - controller.statusLabel.frame.maxX, 16, accuracy: 0.5)
        let categoryFrame = controller.categoryLabel.convert(controller.categoryLabel.bounds, to: controller.categoryPill)
        let categoryTextWidth = ((controller.categoryLabel.text ?? "") as NSString).size(withAttributes: [.font: controller.categoryLabel.font ?? UIFont.systemFont(ofSize: 13)]).width
        XCTAssertGreaterThanOrEqual(categoryFrame.width, categoryTextWidth - 1)
        XCTAssertEqual(categoryFrame.minX, 12, accuracy: 0.5)
        XCTAssertEqual(controller.categoryPill.bounds.width - categoryFrame.maxX, 12, accuracy: 0.5)
        let pillInHeader = controller.categoryPill.convert(controller.categoryPill.bounds, to: controller.header)
        XCTAssertEqual(pillInHeader.minX, 16, accuracy: 0.5)
        let dateInHeader = controller.dateLabel.convert(controller.dateLabel.bounds, to: controller.header)
        XCTAssertLessThanOrEqual(dateInHeader.maxX, controller.header.bounds.width - 16 + 0.5)
        let initial = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { controller.view.layer.render(in: $0.cgContext) }
        let attachment = XCTAttachment(image: initial)
        attachment.name = "Event Details About"
        attachment.lifetime = .keepAlways
        add(attachment)
        controller.tableView.contentOffset.y = controller.heroContainer.bounds.height / 2
        controller.scrollViewDidScroll(controller.tableView)
        XCTAssertEqual(controller.compactTitle.alpha, 0)
        // Ensure the synthetic fixture has enough scrollable content to exercise the fully collapsed state.
        controller.tableView.contentInset.bottom = controller.header.bounds.height
        controller.view.layoutIfNeeded()
        controller.tableView.contentOffset.y = controller.header.bounds.height
        controller.scrollViewDidScroll(controller.tableView)
        controller.view.layoutIfNeeded()
        controller.updateCollapsingHeader()
        XCTAssertEqual(controller.compactTitle.alpha, 1)
        XCTAssertGreaterThan(controller.heroPager.transform.ty, 0)
        let scrolledImage = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { controller.view.layer.render(in: $0.cgContext) }
        let scrolled = XCTAttachment(image: scrolledImage)
        scrolled.name = "Event Details Collapsed Header"
        scrolled.lifetime = .keepAlways
        add(scrolled)
        controller.tableView.contentOffset.y = 0
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        XCTAssertEqual(controller.compactTitle.alpha, 0)
    }

    func testCompactTitleHiddenBeforeLayoutAndShortCategoryDoesNotStretch() throws {
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        controller.eventDetailsVM = EventDetailsViewModel(service: EventDetailsMockService())
        controller.selectedEvent = KitapiEvent(id: "e1", title: "Testing title", category: "Testing", status: "completed", startDate: "07-10-2026", endDate: "10-10-2026", imageUrl: nil)
        controller.loadViewIfNeeded()
        controller.heroContainer.bounds.size = .zero
        controller.compactTitle.alpha = 1
        controller.updateCollapsingHeader()
        XCTAssertEqual(controller.compactTitle.alpha, 0)
        for width in [CGFloat(320), 393, 430] {
            controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 852)
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            let font = controller.categoryLabel.font ?? UIFont.systemFont(ofSize: 13)
            let expected = ceil(((controller.categoryLabel.text ?? "") as NSString).size(withAttributes: [.font: font]).width) + 25
            XCTAssertEqual(controller.categoryPill.bounds.width, expected, accuracy: 1)
            let date = controller.dateLabel.convert(controller.dateLabel.bounds, to: controller.header)
            XCTAssertLessThanOrEqual(date.maxX, width - 16 + 0.5)
            XCTAssertEqual(controller.compactTitle.alpha, 0)
        }
        let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: controller.view.bounds).image { controller.view.layer.render(in: $0.cgContext) })
        attachment.name = "Short Category and Bottom Right Status"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testStartedEventHidesBookingFooter() async throws {
        let controller = try XCTUnwrap(VCManager.openEventDetailsVC())
        let service = EventDetailsMockService()
        service.status = "live"
        controller.selectedEvent = try EventDetailsMockService.fixture(status: "live").event
        controller.eventDetailsVM = EventDetailsViewModel(service: service)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        await Task.yield()
        await Task.yield()
        controller.view.layoutIfNeeded()
        XCTAssertTrue(controller.footer.isHidden)
        XCTAssertEqual(controller.footer.bounds.height, 0, accuracy: 0.1)
        XCTAssertFalse(controller.bookingButton.isEnabled)
        XCTAssertTrue(controller.eventDetailsVM.registrationChecked)
    }
}

@MainActor
final class EventDetailsMockService: EventDetailsServing {
    var status = "upcoming"
    var paid = false
    var failBatches = false
    var failParticipants = false
    var registrationCalls = 0
    var existing: [EventParticipation] = []

    static func fixture(id: String = "e1", status: String = "upcoming") throws -> EventDetails {
        let json = """
        {"id":"\(id)","title":"My Colorful World – Drawing Challenge","category":"Art & Creativity","status":"\(status)","startDate":"20-12-2026","endDate":"24-12-2026","deadlineDate":"18-12-2026","isActive":true,"feeAmount":"0.00","description":"Unleash your creativity and draw a picture of your favourite place, person, animal, or imaginary world!","instructions":[{"step":1,"text":"Draw a picture based on the theme My Colorful World."},{"step":2,"text":"Upload your artwork before the deadline."}],"prizesDescription":"Winners will be announced here.","imageUrl":{"url":"https://example.com/1.png"},"images":[{"url":"https://example.com/1.png"},"https://example.com/2.png"]}
        """
        return try JSONDecoder().decode(EventDetails.self, from: Data(json.utf8))
    }

    func details(eventID: String) async throws -> EventDetails { try Self.fixture(id: eventID, status: status) }
    func batches(eventID: String) async throws -> [EventBatchSummary] {
        if failBatches { throw EventServiceError.server("Batches unavailable") }
        return paid ? [EventBatchSummary(id: "b1")] : []
    }
    func participants(eventID: String, page: Int) async throws -> EventParticipantPage {
        if failParticipants { throw EventServiceError.server("Participants unavailable") }
        return EventParticipantPage(participants: [], pagination: EventPagination(currentPage: page, totalPages: 1, totalCount: 0, limit: 20))
    }
    func myParticipations(eventID: String) async throws -> [EventParticipation] { existing }
    func registerFree(eventID: String, childID: String) async throws -> EventParticipation {
        registrationCalls += 1
        let result = EventParticipation(id: "p1", childId: childID, status: "registered", child: nil)
        existing.append(result)
        return result
    }
}

private final class EventDetailsURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "details.test" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            var bytes = Data()
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                bytes.append(contentsOf: buffer.prefix(count))
            }
            data = bytes
        }
        let body = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }
        let valid = request.httpMethod == "POST" && url.path == "/api/events/parent/e1/register" && body?["hasAgreedTerms"] == "true" && body?["childId"] == "child1"
        let json = valid ? "{\"success\":true,\"data\":{\"id\":\"p1\",\"childId\":\"child1\",\"status\":\"registered\"}}" : "{\"success\":false,\"message\":\"Bad request\"}"
        guard let response = HTTPURLResponse(url: url, statusCode: valid ? 201 : 400, httpVersion: nil, headerFields: nil) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
