import Foundation

@MainActor protocol EventPaymentServing {
    func registrations(eventID: String) async throws -> [EventPaidRegistration]
    func create(childID: String, batchID: String, grade: String?, school: String?) async throws -> EventPaidRegistration
    func order(registrationID: String) async throws -> EventPaymentOrder
    func verify(registrationID: String, proof: EventPaymentProof) async throws -> EventPaidRegistration
    func registration(id: String) async throws -> EventPaidRegistration
}

@MainActor struct EventPaymentService: EventPaymentServing {
    var network = EventDetailsService()
    func registrations(eventID: String) async throws -> [EventPaidRegistration] {
        var records: [EventPaidRegistration] = []
        var page = 1
        while true {
            let response: EventRegistrationPage = try await network.execute(path: "/api/event-registrations/my", query: [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: "50")])
            guard response.pagination.currentPage == page else { throw EventServiceError.invalidResponse }
            records += response.registrations.filter { ($0.eventId ?? $0.event?.id) == eventID }
            if response.registrations.isEmpty || page >= response.pagination.totalPages { return records }
            page += 1
            try Task.checkCancellation()
        }
    }
    func create(childID: String, batchID: String, grade: String?, school: String?) async throws -> EventPaidRegistration {
        var parameters = ["childId": childID, "eventBatchId": batchID, "hasAgreedConsent": "true"]
        if let grade, !grade.isEmpty { parameters["grade"] = grade }
        if let school, !school.isEmpty { parameters["schoolName"] = school }
        return try await network.execute(path: "/api/event-registrations", method: "POST", body: JSONSerialization.data(withJSONObject: parameters), acceptConflict: true)
    }
    func order(registrationID: String) async throws -> EventPaymentOrder {
        try await network.execute(path: "/api/event-registrations/\(network.identifier(registrationID))/payment-order", method: "POST")
    }
    func verify(registrationID: String, proof: EventPaymentProof) async throws -> EventPaidRegistration {
        try await network.execute(path: "/api/event-registrations/\(network.identifier(registrationID))/verify-payment", method: "POST", body: JSONEncoder().encode(proof))
    }
    func registration(id: String) async throws -> EventPaidRegistration {
        try await network.execute(path: "/api/event-registrations/\(network.identifier(id))")
    }
}
