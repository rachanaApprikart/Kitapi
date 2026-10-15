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
    var client: any APIClientProtocol = APIClient()

    func details(eventID: String) async throws -> EventDetails {
        try await client.execute(EventEndpoint.details(eventID: eventID))
    }

    func batches(eventID: String) async throws -> [EventBatchSummary] {
        try await client.execute(EventEndpoint.batches(eventID: eventID))
    }

    func participants(eventID: String, page: Int) async throws -> EventParticipantPage {
        try await client.execute(EventEndpoint.participants(eventID: eventID, page: page))
    }

    func myParticipations(eventID: String) async throws -> [EventParticipation] {
        try await client.execute(EventEndpoint.myParticipations(eventID: eventID))
    }

    func registerFree(eventID: String, childID: String) async throws -> EventParticipation {
        try await client.execute(EventEndpoint.registerFree(eventID: eventID, childID: childID))
    }
}
