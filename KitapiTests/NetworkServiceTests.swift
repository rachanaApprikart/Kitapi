import XCTest
@testable import Kitapi

@MainActor
final class NetworkServiceTests: XCTestCase {
    func testExistingJSONAPIUsesSharedClientAndPreservesResponseContract() async {
        let session = session()
        defer { session.invalidateAndCancel() }
        var logs: [String] = []
        let client = APIClient(session: session, tokenProvider: { "unit-secret" }, logger: { logs.append($0) }, authenticationFailureHandler: {})
        let result: APIResponse<Fixture> = await APIClient.callAPIWithRawData(url: "https://shared-client.test/json", method: .post, body: Data(#"{"name":"Test"}"#.utf8), client: client)
        XCTAssertEqual(result.data?.value, "ok")
        XCTAssertNil(result.error)
        XCTAssertEqual(result.statusCode, 200)
        XCTAssertTrue(logs.contains { $0.contains("RESPONSE status=200") })
        XCTAssertFalse(logs.contains { $0.contains("unit-secret") })
    }

    func testExistingMultipartAPIUsesSameTransport() async {
        let session = session()
        defer { session.invalidateAndCancel() }
        let client = APIClient(session: session, tokenProvider: { "unit-secret" }, logger: { _ in }, authenticationFailureHandler: {})
        let result: APIResponse<Fixture> = await APIClient.callAPIWithFormData(url: "https://shared-client.test/form", parameters: ["name": "Test"], client: client)
        XCTAssertEqual(result.data?.value, "ok")
        XCTAssertNil(result.error)
    }

    func testLegacyForbiddenStillUsesAuthenticationHandlerButPaymentForbiddenDoesNot() async throws {
        let session = session()
        defer { session.invalidateAndCancel() }
        var authenticationFailures = 0
        let client = APIClient(session: session, baseURL: "https://shared-client.test", tokenProvider: { "unit-secret" }, logger: { _ in }, authenticationFailureHandler: { authenticationFailures += 1 })
        let result: APIResponse<Fixture> = await APIClient.callAPIWithRawData(url: "https://shared-client.test/forbidden", client: client)
        guard case .authenticationFailed = result.error else { XCTFail("Legacy 403 policy changed"); return }
        XCTAssertEqual(authenticationFailures, 1)
        do {
            let _: EventPaymentOrder = try await client.execute(PaymentEndpoint.paymentOrder(registrationID: "forbidden"))
            XCTFail("Expected payment authorization error")
        } catch { XCTAssertEqual(error.localizedDescription, "Exit child mode to register") }
        XCTAssertEqual(authenticationFailures, 1)
    }

    func testTypedUnauthorizedUsesExistingAuthenticationHandling() async {
        let session = session()
        defer { session.invalidateAndCancel() }
        var authenticationFailures = 0
        let client = APIClient(session: session, baseURL: "https://shared-client.test", tokenProvider: { "unit-secret" }, logger: { _ in }, authenticationFailureHandler: { authenticationFailures += 1 })
        do {
            let _: EventDetails = try await client.execute(EventEndpoint.details(eventID: "unauthorized"))
            XCTFail("Expected sign in error")
        } catch { XCTAssertEqual(error.localizedDescription, EventServiceError.signInRequired.localizedDescription) }
        XCTAssertEqual(authenticationFailures, 1)
    }

    func testDecodingErrorsRetainLegacyContractAndTypedDiagnostics() async {
        let session = session()
        defer { session.invalidateAndCancel() }
        let client = APIClient(session: session, baseURL: "https://shared-client.test", tokenProvider: { "unit-secret" }, logger: { _ in }, authenticationFailureHandler: {})
        let result: APIResponse<Fixture> = await APIClient.callAPIWithRawData(url: "https://shared-client.test/malformed", client: client)
        guard case .decodingFailed = result.error else { XCTFail("Legacy decoding contract changed"); return }
        do {
            let _: EventDetails = try await client.execute(EventEndpoint.details(eventID: "malformed"))
            XCTFail("Expected typed decoding failure")
        } catch { XCTAssertTrue(error is DecodingError) }
    }

    private func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SharedClientURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private struct Fixture: Decodable { let value: String }
}

private final class SharedClientURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "shared-client.test" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        var status = 200
        var json = #"{"value":"ok"}"#
        if url.path.contains("/forbidden") { status = 403; json = #"{"success":false,"message":"Exit child mode to register"}"# }
        else if url.path.hasSuffix("unauthorized") { status = 401; json = #"{"success":false,"message":"Session expired"}"# }
        else if url.path.hasSuffix("malformed") { json = "not JSON" }
        else if url.path == "/form", request.httpMethod != "POST" || request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") != true {
            status = 400; json = #"{"success":false,"message":"Invalid multipart request"}"#
        }
        if request.value(forHTTPHeaderField: "Authorization") != "Bearer unit-secret" { status = 401 }
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
