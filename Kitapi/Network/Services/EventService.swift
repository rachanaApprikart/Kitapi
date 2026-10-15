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
    var client: any APIClientProtocol = APIClient()

    func request(filter: EventListFilter, page: Int) throws -> URLRequest {
        try client.request(for: EventEndpoint.list(filter: filter, page: page))
    }

    func fetchEvents(filter: EventListFilter, page: Int) async throws -> EventPage {
        try await client.execute(EventEndpoint.list(filter: filter, page: page), describeResult: { (result: EventPage) in
            "events=\(result.events.count) currentPage=\(result.pagination.currentPage) totalPages=\(result.pagination.totalPages) totalCount=\(result.pagination.totalCount)"
        })
    }
}
