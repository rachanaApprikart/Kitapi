import Foundation

@MainActor
protocol EventDetailsServing {
    func details(eventID: String) async throws -> EventDetails
    func batches(eventID: String) async throws -> [EventBatchSummary]
    func participants(eventID: String, page: Int) async throws -> EventParticipantPage
    func myParticipations(eventID: String) async throws -> [EventParticipation]
    func registerFree(eventID: String, childID: String) async throws -> EventParticipation
}

@MainActor
struct EventDetailsService: EventDetailsServing {
    var session: URLSession = .shared
    var baseURL: String = BASE_URL
    var tokenProvider: () -> String? = { AppUserDefaults.authorizationToken }
    var logger: (String) -> Void = { EventAPILog.write($0) }

    func details(eventID: String) async throws -> EventDetails {
        try await execute(path: "/api/events/get-event-by-id/\(identifier(eventID))")
    }

    func batches(eventID: String) async throws -> [EventBatchSummary] {
        try await execute(path: "/api/event-batches/event/\(identifier(eventID))")
    }

    func participants(eventID: String, page: Int) async throws -> EventParticipantPage {
        try await execute(path: "/api/events/\(identifier(eventID))/participants", query: [URLQueryItem(name: "page", value: String(max(1, page))), URLQueryItem(name: "limit", value: "20")])
    }

    func myParticipations(eventID: String) async throws -> [EventParticipation] {
        try await execute(path: "/api/events/parent/events/\(identifier(eventID))/my-participations")
    }

    func registerFree(eventID: String, childID: String) async throws -> EventParticipation {
        let body = try JSONSerialization.data(withJSONObject: ["childId": childID, "hasAgreedTerms": "true"])
        return try await execute(path: "/api/events/parent/\(identifier(eventID))/register", method: "POST", body: body)
    }

    func identifier(_ value: String) throws -> String {
        guard !value.isEmpty, value.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_" )).contains($0) }) else { throw EventServiceError.invalidURL }
        return value
    }

    func execute<Value: Decodable>(path: String, query: [URLQueryItem] = [], method: String = "GET", body: Data? = nil, acceptConflict: Bool = false) async throws -> Value {
        let context = "[EventAPI][\(UUID().uuidString.prefix(8))] \(method) \(path)"
        let start = ProcessInfo.processInfo.systemUptime
        var status: Int?
        logger("\(context) REQUEST")
        do {
            guard var components = URLComponents(string: baseURL + path) else { throw EventServiceError.invalidURL }
            components.queryItems = query.isEmpty ? nil : query
            guard let url = components.url, url.scheme == "https", url.host != nil else { throw EventServiceError.invalidURL }
            guard let token = tokenProvider(), !token.isEmpty else { throw EventServiceError.signInRequired }
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.httpBody = body
            request.timeoutInterval = 30
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("en", forHTTPHeaderField: "Accept-Language")
            logger("\(context) URL \(url.absoluteString)")
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else { throw EventServiceError.invalidResponse }
            status = http.statusCode
            logger("\(context) RESPONSE status=\(http.statusCode)")
            #if DEBUG
            logger("\(context) RESPONSE BODY\n\(EventAPILog.responseBody(data))")
            #endif
            if http.statusCode == 401 { throw EventServiceError.signInRequired }
            guard (200...299).contains(http.statusCode) || (acceptConflict && http.statusCode == 409) else {
                let error = try? JSONDecoder().decode(APIError.self, from: data)
                throw EventServiceError.server(error?.message ?? "Unable to load event information. Please try again.")
            }
            let envelope = try JSONDecoder().decode(EventAPIEnvelope<Value>.self, from: data)
            guard envelope.success || (acceptConflict && http.statusCode == 409), let value = envelope.data else { throw EventServiceError.server(envelope.message ?? "Missing event information") }
            logger("\(context) SUCCESS durationMs=\(Int((ProcessInfo.processInfo.systemUptime - start) * 1000))")
            return value
        } catch {
            let cancelled = error is CancellationError || (error as? URLError)?.code == .cancelled
            logger("\(context) \(cancelled ? "CANCELLED" : "FAILED") status=\(status.map(String.init) ?? "none") reason=\(EventAPILog.errorSummary(error))")
            throw error
        }
    }
}
