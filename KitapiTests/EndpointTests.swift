import XCTest
@testable import Kitapi

@MainActor
final class EndpointTests: XCTestCase {
    func testEventPathsAndMethods() throws {
        let cases: [(EventEndpoint, String, HTTPMethod)] = [
            (.list(filter: .all, page: 1), "/api/events/get-events", .get),
            (.details(eventID: "e1"), "/api/events/get-event-by-id/e1", .get),
            (.batches(eventID: "e1"), "/api/event-batches/event/e1", .get),
            (.participants(eventID: "e1", page: 1), "/api/events/e1/participants", .get),
            (.myParticipations(eventID: "e1"), "/api/events/parent/events/e1/my-participations", .get),
            (.registerFree(eventID: "e1", childID: "child1"), "/api/events/parent/e1/register", .post)
        ]
        for (endpoint, path, method) in cases {
            XCTAssertEqual(try endpoint.path, path)
            XCTAssertEqual(endpoint.method, method)
            XCTAssertFalse(endpoint.acceptsConflictResponse)
            if method == .get { XCTAssertNil(try endpoint.body) }
        }
    }

    func testPaymentPathsMethodsAndConflictPolicy() throws {
        let proof = EventPaymentProof(razorpayOrderId: "order1", razorpayPaymentId: "pay1", razorpaySignature: "signature")
        let cases: [(PaymentEndpoint, String, HTTPMethod)] = [
            (.registrations(page: 1), "/api/event-registrations/my", .get),
            (.createRegistration(childID: "child1", batchID: "b1", grade: nil, school: nil), "/api/event-registrations", .post),
            (.paymentOrder(registrationID: "r1"), "/api/event-registrations/r1/payment-order", .post),
            (.verifyPayment(registrationID: "r1", proof: proof), "/api/event-registrations/r1/verify-payment", .post),
            (.registration(id: "r1"), "/api/event-registrations/r1", .get)
        ]
        for (endpoint, path, method) in cases {
            XCTAssertEqual(try endpoint.path, path)
            XCTAssertEqual(endpoint.method, method)
            XCTAssertEqual(endpoint.acceptsConflictResponse, path == "/api/event-registrations")
        }
        XCTAssertNil(try PaymentEndpoint.paymentOrder(registrationID: "r1").body)
        XCTAssertNil(try PaymentEndpoint.registration(id: "r1").body)
        XCTAssertNil(try PaymentEndpoint.registrations(page: 1).body)
    }

    func testConsentAndOptionalRegistrationFieldsStayUnchanged() throws {
        let free = try body(EventEndpoint.registerFree(eventID: "e1", childID: "child1"))
        XCTAssertEqual(free, ["childId": "child1", "hasAgreedTerms": "true"])
        let paid = try body(PaymentEndpoint.createRegistration(childID: "child1", batchID: "b1", grade: nil, school: ""))
        XCTAssertEqual(paid, ["childId": "child1", "eventBatchId": "b1", "hasAgreedConsent": "true"])
        let optional = try body(PaymentEndpoint.createRegistration(childID: "child1", batchID: "b1", grade: "Grade 3", school: "Little Stars"))
        XCTAssertEqual(optional["grade"], "Grade 3")
        XCTAssertEqual(optional["schoolName"], "Little Stars")
        let proof = EventPaymentProof(razorpayOrderId: "order1", razorpayPaymentId: "pay1", razorpaySignature: "signature")
        XCTAssertEqual(try body(PaymentEndpoint.verifyPayment(registrationID: "r1", proof: proof)), ["razorpayOrderId": "order1", "razorpayPaymentId": "pay1", "razorpaySignature": "signature"])
    }

    func testPaginationAndFilters() {
        let list = query(EventEndpoint.list(filter: .completed, page: -1))
        XCTAssertEqual(list, ["page": "1", "limit": "10", "sortBy": "startDate", "sortOrder": "DESC", "status": "completed"])
        XCTAssertNil(query(EventEndpoint.list(filter: .all, page: 1))["status"])
        XCTAssertEqual(query(EventEndpoint.participants(eventID: "e1", page: 0)), ["page": "1", "limit": "20"])
        XCTAssertEqual(query(PaymentEndpoint.registrations(page: -1)), ["page": "1", "limit": "50"])
        XCTAssertTrue(EventEndpoint.details(eventID: "e1").queryItems.isEmpty)
        XCTAssertTrue(PaymentEndpoint.paymentOrder(registrationID: "r1").queryItems.isEmpty)
        XCTAssertEqual(EventEndpoint.list(filter: .live, page: 2).logDetails, " filter=live page=2")
    }

    func testInvalidIdentifiersCannotProduceRequests() throws {
        let client = APIClient(baseURL: "https://endpoint.test", tokenProvider: { "unit-test-token" })
        for id in ["", "../other", "one/two", "id?admin=true", "id%2Fother", "id with spaces"] {
            XCTAssertThrowsError(try EndpointIdentifier.validated(id))
            XCTAssertThrowsError(try client.request(for: EventEndpoint.details(eventID: id)))
            XCTAssertThrowsError(try client.request(for: PaymentEndpoint.paymentOrder(registrationID: id)))
            XCTAssertThrowsError(try client.request(for: EventEndpoint.registerFree(eventID: "e1", childID: id)))
            XCTAssertThrowsError(try client.request(for: PaymentEndpoint.createRegistration(childID: "child1", batchID: id, grade: nil, school: nil)))
        }
        XCTAssertEqual(try EndpointIdentifier.validated("abc-123_456"), "abc-123_456")
    }

    func testSharedClientBuildsAuthenticatedJSONRequests() throws {
        let endpoint = EventEndpoint.registerFree(eventID: "e1", childID: "child1")
        let client = APIClient(baseURL: "https://endpoint.test", tokenProvider: { "unit-test-token" })
        let request = try client.request(for: endpoint)
        XCTAssertEqual(request.url?.absoluteString, "https://endpoint.test/api/events/parent/e1/register")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, try endpoint.body)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer unit-test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "en")
        XCTAssertEqual(request.timeoutInterval, 30)
        XCTAssertThrowsError(try APIClient(baseURL: "http://endpoint.test", tokenProvider: { "token" }).request(for: endpoint))
        XCTAssertThrowsError(try APIClient(tokenProvider: { "" }).request(for: endpoint))
    }

    private func body(_ endpoint: any APIEndpoint) throws -> [String: String] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(try endpoint.body)) as? [String: String])
    }

    private func query(_ endpoint: any APIEndpoint) -> [String: String] {
        Dictionary(uniqueKeysWithValues: endpoint.queryItems.map { ($0.name, $0.value ?? "") })
    }
}
