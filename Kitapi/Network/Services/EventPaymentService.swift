import Foundation

@MainActor
protocol EventPaymentServing {
    func registrations(eventID: String) async throws -> [EventPaidRegistration]
    func create(childID: String, batchID: String, grade: String?, school: String?) async throws -> EventPaidRegistration
    func order(registrationID: String) async throws -> EventPaymentOrder
    func verify(registrationID: String, proof: EventPaymentProof) async throws -> EventPaidRegistration
    func registration(id: String) async throws -> EventPaidRegistration
}

@MainActor
struct EventPaymentService: EventPaymentServing {
    var client: any APIClientProtocol = APIClient()

    func registrations(eventID: String) async throws -> [EventPaidRegistration] {
        var records: [EventPaidRegistration] = []
        var page = 1
        while true {
            let response: EventRegistrationPage = try await client.execute(PaymentEndpoint.registrations(page: page))
            guard response.pagination.currentPage == page else { throw EventServiceError.invalidResponse }
            records += response.registrations.filter { ($0.eventId ?? $0.event?.id) == eventID }
            if response.registrations.isEmpty || page >= response.pagination.totalPages { return records }
            page += 1
            try Task.checkCancellation()
        }
    }

    func create(childID: String, batchID: String, grade: String?, school: String?) async throws -> EventPaidRegistration {
        try await client.execute(PaymentEndpoint.createRegistration(childID: childID, batchID: batchID, grade: grade, school: school))
    }

    func order(registrationID: String) async throws -> EventPaymentOrder {
        try await client.execute(PaymentEndpoint.paymentOrder(registrationID: registrationID))
    }

    func verify(registrationID: String, proof: EventPaymentProof) async throws -> EventPaidRegistration {
        try await client.execute(PaymentEndpoint.verifyPayment(registrationID: registrationID, proof: proof))
    }

    func registration(id: String) async throws -> EventPaidRegistration {
        try await client.execute(PaymentEndpoint.registration(id: id))
    }
}
