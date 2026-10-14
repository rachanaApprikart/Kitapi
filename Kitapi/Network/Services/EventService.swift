import Foundation

@MainActor
protocol EventListing {
    func fetchEvents(filter: EventListFilter, page: Int) async throws -> EventPage
}

enum EventServiceError: LocalizedError {
    case invalidURL, invalidResponse, signInRequired
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Unable to open events. Please try again."
        case .invalidResponse: return "Unable to read events. Please try again."
        case .signInRequired: return "Please sign in again to view events."
        case .server(let message): return message
        }
    }
}

@MainActor
struct EventService: EventListing {
    var session: URLSession = .shared
    var baseURL: String = BASE_URL
    var tokenProvider: () -> String? = { AppUserDefaults.authorizationToken }
    var logger: (String) -> Void = { EventAPILog.write($0) }

    func request(filter: EventListFilter, page: Int) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + "/api/events/get-events") else {
            throw EventServiceError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(max(1, page))),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "sortBy", value: "startDate"),
            URLQueryItem(name: "sortOrder", value: "DESC")
        ]
        if let status = filter.apiStatus {
            components.queryItems?.append(URLQueryItem(name: "status", value: status))
        }
        guard let url = components.url, url.scheme == "https", url.host != nil else {
            throw EventServiceError.invalidURL
        }
        guard let token = tokenProvider(), !token.isEmpty else {
            throw EventServiceError.signInRequired
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        return request
    }

    func fetchEvents(filter: EventListFilter, page: Int) async throws -> EventPage {
        let requestID = UUID().uuidString.prefix(8)
        let context = "[EventAPI][\(requestID)] GET /api/events/get-events filter=\(filter.rawValue) page=\(max(1, page))"
        let started = ProcessInfo.processInfo.systemUptime
        var statusCode: Int?
        logger("\(context) REQUEST")
        do {
            let request = try request(filter: filter, page: page)
            logger("\(context) URL \(request.url?.absoluteString ?? "<invalid>")")
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else { throw EventServiceError.invalidResponse }
            statusCode = http.statusCode
            logger("\(context) RESPONSE status=\(http.statusCode) bytes=\(data.count)")
            #if DEBUG
            logger("\(context) RESPONSE BODY\n\(EventAPILog.responseBody(data))")
            #endif
            if http.statusCode == 401 { throw EventServiceError.signInRequired }
            guard (200...299).contains(http.statusCode) else {
                let error = try? JSONDecoder().decode(APIError.self, from: data)
                throw EventServiceError.server(error?.message ?? "Unable to load events. Please try again.")
            }
            let responseBody = try JSONDecoder().decode(EventListResponse.self, from: data)
            guard responseBody.success, let result = responseBody.data else {
                throw EventServiceError.server(responseBody.message ?? "Unable to load events. Please try again.")
            }
            let elapsed = Int((ProcessInfo.processInfo.systemUptime - started) * 1000)
            logger("\(context) SUCCESS events=\(result.events.count) currentPage=\(result.pagination.currentPage) totalPages=\(result.pagination.totalPages) totalCount=\(result.pagination.totalCount) durationMs=\(elapsed)")
            return result
        } catch {
            let elapsed = Int((ProcessInfo.processInfo.systemUptime - started) * 1000)
            let cancelled = error is CancellationError || (error as? URLError)?.code == .cancelled
            logger("\(context) \(cancelled ? "CANCELLED" : "FAILED") status=\(statusCode.map(String.init) ?? "none") durationMs=\(elapsed) reason=\(EventAPILog.errorSummary(error))")
            throw error
        }
    }
}
