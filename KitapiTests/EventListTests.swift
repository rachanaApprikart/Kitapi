import XCTest
import UIKit
@testable import Kitapi

@MainActor
final class EventListTests: XCTestCase {
    func testAllFourTabsAndQueryParameters() throws {
        XCTAssertEqual(EventListFilter.allCases.map(\.title), ["All", "Live", "Upcoming", "Completed"])
        let service = EventService(tokenProvider: { "unit-test-token" })
        for filter in EventListFilter.allCases {
            let request = try service.request(filter: filter, page: 2)
            let url = try XCTUnwrap(request.url)
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(items["page"], "2")
            XCTAssertNil(items[" page"])
            XCTAssertEqual(items["status"], filter.apiStatus)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer unit-test-token")
        }
    }

    func testRequestRejectsMissingAuthentication() {
        XCTAssertThrowsError(try EventService(tokenProvider: { nil }).request(filter: .all, page: 1))
    }

    func testCategoryColorsAreStableAndUsePaletteFallback() {
        XCTAssertTrue(EventCardStyle.categoryTint(nil).isEqual(UIColor.gradientColor1))
        XCTAssertTrue(EventCardStyle.categoryTint(" ").isEqual(UIColor.gradientColor1))
        XCTAssertTrue(EventCardStyle.categoryTint("Painting").isEqual(EventCardStyle.categoryTint(" painting ")))
        XCTAssertEqual(EventCardStyle.categoryTint("Painting").cgColor.alpha, 0.12, accuracy: 0.001)
    }

    func testCompletedStatusRetainsAPIName() {
        let value = KitapiEvent(id: "completed", title: "Event", category: nil, status: "completed", startDate: nil, endDate: nil, imageUrl: nil)
        XCTAssertEqual(value.displayStatus, "Completed")
    }

    func testDatesAndMissingDateFallback() {
        XCTAssertEqual(EventDateText.range(start: "01-12-2026", end: "22-12-2026"), "1st Dec – 22nd Dec – 2026")
        XCTAssertEqual(EventDateText.range(start: "23-10-2026", end: "29-10-2026"), "23rd Oct – 29th Oct – 2026")
        XCTAssertEqual(EventDateText.range(start: "30-10-2026", end: "02-11-2026"), "30th Oct – 2nd Nov – 2026")
        XCTAssertEqual(EventDateText.range(start: "30-12-2026", end: "02-01-2027"), "30th Dec 2026 – 2nd Jan 2027")
        XCTAssertEqual(EventDateText.range(start: "01-12-2026", end: "01-12-2026"), "1st Dec 2026")
        for day in [11, 12, 13] {
            XCTAssertEqual(EventDateText.range(start: "\(day)-10-2026", end: nil), "\(day)th Oct 2026")
        }
        XCTAssertEqual(EventDateText.range(start: nil, end: "21-10-2026"), "Until 21st Oct 2026")
        XCTAssertEqual(EventDateText.range(start: "bad", end: nil), "Dates to be announced")
    }

    func testDecodesObjectStringAndNullImagesAndUnknownStatus() throws {
        let json = """
        [{"id":"1","title":"Drawing","status":"live","imageUrl":{"url":"https://example.com/a.png"}},
         {"id":"2","title":"Workshop","status":"upcoming","imageUrl":"https://example.com/b.png"},
         {"id":"3","title":"Cancelled","status":"cancelled","imageUrl":null}]
        """
        let events = try JSONDecoder().decode([KitapiEvent].self, from: Data(json.utf8))
        XCTAssertEqual(events[0].imageUrl?.url, "https://example.com/a.png")
        XCTAssertEqual(events[1].imageUrl?.url, "https://example.com/b.png")
        XCTAssertNil(events[2].imageUrl)
        XCTAssertEqual(events[2].displayStatus, "Cancelled")
    }

    func testPaginationDeduplicatesAndStopsAtLastPage() async {
        let service = MockEventListing()
        service.pages = [page([event("1"), event("2")], current: 1, total: 2), page([event("2"), event("3")], current: 2, total: 2)]
        let loader = EventListViewModel(service: service)
        await loader.reload()
        await loader.loadNextPage()
        await loader.loadNextPage()
        XCTAssertEqual(loader.events.map(\.id), ["1", "2", "3"])
        XCTAssertEqual(service.calls.count, 2)
        XCTAssertFalse(loader.canLoadMore)
    }

    func testErrorCanRetrySamePage() async {
        let service = MockEventListing()
        service.failNext = true
        service.pages = [page([event("1")], current: 1, total: 1)]
        let loader = EventListViewModel(service: service)
        await loader.reload(filter: .completed)
        XCTAssertNotNil(loader.errorMessage)
        XCTAssertFalse(loader.isLoading)
        await loader.loadNextPage()
        XCTAssertNil(loader.errorMessage)
        XCTAssertEqual(service.calls.map(\.1), [1, 1])
        XCTAssertEqual(loader.events.count, 1)
    }

    func testOldResponseCannotReplaceNewTab() async {
        let service = SuspendedEventListing()
        let loader = EventListViewModel(service: service)
        let oldRequest = Task { await loader.reload(filter: .all) }
        while service.pending == nil { await Task.yield() }
        await loader.reload(filter: .live)
        service.pending?.resume(returning: page([event("old")], current: 1, total: 1))
        service.pending = nil
        await oldRequest.value
        XCTAssertEqual(loader.filter, .live)
        XCTAssertEqual(loader.events.map(\.id), ["new"])
        XCTAssertFalse(loader.isLoading)
    }

    func testNetworkingUsesURLProtocolAndDisplaysServerError() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EventMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var logs: [String] = []
        let service = EventService(session: session, baseURL: "https://example.com", tokenProvider: { "secret-test-token" }, logger: { logs.append($0) })
        let result = try await service.fetchEvents(filter: .live, page: 1)
        XCTAssertEqual(result.events.first?.id, "network")
        do {
            _ = try await service.fetchEvents(filter: .completed, page: 1)
            XCTFail("Expected HTTP error")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Events are unavailable")
        }
        XCTAssertTrue(logs.contains { $0.contains("GET /api/events/get-events filter=live page=1") && $0.contains("REQUEST") })
        XCTAssertTrue(logs.contains { $0.contains("SUCCESS events=1") && $0.contains("durationMs=") })
        XCTAssertTrue(logs.contains { $0.contains("FAILED status=503") && $0.contains("Events are unavailable") })
        XCTAssertFalse(logs.contains { $0.contains("secret-test-token") || $0.contains("Bearer") || $0.contains("Authorization") })
    }

    func testMissingTokenLogsFailureBeforeSendingRequest() async {
        var logs: [String] = []
        let service = EventService(tokenProvider: { nil }, logger: { logs.append($0) })
        do {
            _ = try await service.fetchEvents(filter: .upcoming, page: 3)
            XCTFail("Expected authentication error")
        } catch {
            XCTAssertTrue(logs.contains { $0.contains("filter=upcoming page=3 FAILED status=none") })
            XCTAssertFalse(logs.contains { $0.contains("RESPONSE") })
        }
    }

    func testResponseBodyPrintsPayloadAndRedactsNestedCredentials() {
        let json = Data("{\"success\":true,\"data\":{\"title\":\"Drawing event\",\"access_token\":\"private-token\",\"items\":[{\"password\":\"private-password\",\"status\":\"live\"}]}}".utf8)
        let output = EventAPILog.responseBody(json)
        XCTAssertTrue(output.contains("Drawing event"))
        XCTAssertTrue(output.contains("live"))
        XCTAssertTrue(output.contains("<redacted>"))
        XCTAssertFalse(output.contains("private-token"))
        XCTAssertFalse(output.contains("private-password"))
        XCTAssertEqual(EventAPILog.responseBody(Data()), "<empty response>")
        XCTAssertEqual(EventAPILog.responseBody(Data("Bad Gateway".utf8)), "Bad Gateway")
    }

    func testDecodingLogIdentifiesFieldWithoutDumpingResponse() throws {
        let json = Data("{\"success\":true,\"data\":{\"events\":[]}}".utf8)
        do {
            _ = try JSONDecoder().decode(EventListResponse.self, from: json)
            XCTFail("Expected missing pagination")
        } catch {
            XCTAssertEqual(EventAPILog.errorSummary(error), "decoding missingKey=data.pagination")
        }
        XCTAssertTrue(EventAPILog.errorSummary(URLError(.timedOut)).contains("network code=-1001"))
        XCTAssertEqual(EventAPILog.errorSummary(CancellationError()), "cancelled")
        XCTAssertEqual(EventAPILog.errorSummary(NetworkError.apiError(APIError(success: false, message: "PIN unavailable"))), "PIN unavailable")
    }

    func testStoryboardLoadsFourTabsAndCardLayout() async throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "KitapiTab", bundle: .main).instantiateViewController(withIdentifier: "EventListViewController") as? EventListViewController)
        let mock = MockEventListing()
        mock.pages = [page([event("1")], current: 1, total: 1)]
        controller.eventListVM = EventListViewModel(service: mock)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 700)
        await Task.yield()
        await Task.yield()
        controller.view.layoutIfNeeded()
        let table = try XCTUnwrap(controller.mainView.subviews.compactMap { $0 as? UITableView }.first)
        XCTAssertEqual(table.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(controller.mainView.subviews.compactMap { $0 as? UIStackView }.first?.arrangedSubviews.count, 4)
        XCTAssertGreaterThan(table.bounds.height, 200)
        XCTAssertTrue(controller.appBgView.layer.sublayers?.first is CAGradientLayer)
        XCTAssertNotNil(table.cellForRow(at: IndexPath(row: 0, section: 0)) as? EventCardCell)
        let image = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Event list layout"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testPaginationPreservesExistingCardAndAppendsRows() async throws {
        let list = try XCTUnwrap(UIStoryboard(name: "KitapiTab", bundle: .main).instantiateViewController(withIdentifier: "EventListViewController") as? EventListViewController)
        let mock = MockEventListing()
        mock.pages = [page((0..<10).map { event(String($0)) }, current: 1, total: 2), page([event("10")], current: 2, total: 2)]
        list.eventListVM = EventListViewModel(service: mock)
        list.loadViewIfNeeded()
        list.view.frame = CGRect(x: 0, y: 0, width: 393, height: 700)
        await Task.yield()
        await Task.yield()
        list.view.layoutIfNeeded()
        let table = try XCTUnwrap(list.mainView.subviews.compactMap { $0 as? UITableView }.first)
        let first = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 0, section: 0)))
        await list.eventListVM.loadNextPage()
        table.layoutIfNeeded()
        XCTAssertEqual(table.numberOfRows(inSection: 0), 11)
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 0, section: 0)) === first)
    }

    func testEventTapPushesDetailsWithSelectedEvent() async throws {
        let list = try XCTUnwrap(UIStoryboard(name: "KitapiTab", bundle: .main).instantiateViewController(withIdentifier: "EventListViewController") as? EventListViewController)
        let mock = MockEventListing()
        let selected = event("selected-event")
        mock.pages = [page([selected], current: 1, total: 1)]
        list.eventListVM = EventListViewModel(service: mock)
        let navigation = UINavigationController(rootViewController: list)
        list.loadViewIfNeeded()
        await Task.yield()
        await Task.yield()
        list.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
        let details = try XCTUnwrap(navigation.topViewController as? EventDetailsViewController)
        details.eventDetailsVM = EventDetailsViewModel(service: EventDetailsMockService())
        XCTAssertEqual(details.eventId, "selected-event")
        XCTAssertEqual(details.selectedEvent?.title, selected.title)
        XCTAssertTrue(details.hidesBottomBarWhenPushed)
        details.loadViewIfNeeded()
        XCTAssertEqual(details.title, selected.title)
        // A rapid second tap must not push a duplicate details screen.
        list.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(navigation.viewControllers.count, 2)
        navigation.popViewController(animated: false)
        XCTAssertTrue(navigation.topViewController === list)
    }

    private func event(_ id: String) -> KitapiEvent {
        KitapiEvent(id: id, title: "Draw and explore your imagination", category: "Christmas special", status: "live", startDate: "01-12-2026", endDate: "22-12-2026", imageUrl: nil)
    }

    private func page(_ events: [KitapiEvent], current: Int, total: Int) -> EventPage {
        EventPage(events: events, pagination: EventPagination(currentPage: current, totalPages: total, totalCount: events.count, limit: 10))
    }
}

@MainActor
private final class MockEventListing: EventListing {
    var pages: [EventPage] = []
    var failNext = false
    var calls: [(EventListFilter, Int)] = []
    func fetchEvents(filter: EventListFilter, page: Int) async throws -> EventPage {
        calls.append((filter, page))
        if failNext { failNext = false; throw EventServiceError.server("Please retry") }
        guard !pages.isEmpty else { throw EventServiceError.invalidResponse }
        return pages.removeFirst()
    }
}

@MainActor
private final class SuspendedEventListing: EventListing {
    var pending: CheckedContinuation<EventPage, any Error>?
    func fetchEvents(filter: EventListFilter, page: Int) async throws -> EventPage {
        if filter == .all {
            return try await withCheckedThrowingContinuation { pending = $0 }
        }
        let event = KitapiEvent(id: "new", title: "New event", category: nil, status: "live", startDate: nil, endDate: nil, imageUrl: nil)
        return EventPage(events: [event], pagination: EventPagination(currentPage: 1, totalPages: 1, totalCount: 1, limit: 10))
    }
}

private final class EventMockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "example.com" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        let isError = url.query?.contains("status=completed") == true
        let json = isError ? "{\"success\":false,\"message\":\"Events are unavailable\"}" : "{\"success\":true,\"data\":{\"events\":[{\"id\":\"network\",\"title\":\"Event\",\"status\":\"live\"}],\"pagination\":{\"currentPage\":1,\"totalPages\":1,\"totalCount\":1,\"limit\":10}}}"
        guard let response = HTTPURLResponse(url: url, statusCode: isError ? 503 : 200, httpVersion: nil, headerFields: nil) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
