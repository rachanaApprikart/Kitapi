import Foundation

enum EventEndpoint: APIEndpoint {
    case list(filter: EventListFilter, page: Int)
    case details(eventID: String)
    case batches(eventID: String)
    case participants(eventID: String, page: Int)
    case myParticipations(eventID: String)
    case registerFree(eventID: String, childID: String)

    var path: String {
        get throws {
            switch self {
            case .list: return "/api/events/get-events"
            case .details(let id): return "/api/events/get-event-by-id/\(try EndpointIdentifier.validated(id))"
            case .batches(let id): return "/api/event-batches/event/\(try EndpointIdentifier.validated(id))"
            case .participants(let id, _): return "/api/events/\(try EndpointIdentifier.validated(id))/participants"
            case .myParticipations(let id): return "/api/events/parent/events/\(try EndpointIdentifier.validated(id))/my-participations"
            case .registerFree(let id, _): return "/api/events/parent/\(try EndpointIdentifier.validated(id))/register"
            }
        }
    }

    var method: HTTPMethod {
        if case .registerFree = self { return .post }
        return .get
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .list(let filter, let page):
            var items = [URLQueryItem(name: "page", value: String(max(1, page))), URLQueryItem(name: "limit", value: "10"), URLQueryItem(name: "sortBy", value: "startDate"), URLQueryItem(name: "sortOrder", value: "DESC")]
            if let status = filter.apiStatus { items.append(URLQueryItem(name: "status", value: status)) }
            return items
        case .participants(_, let page):
            return [URLQueryItem(name: "page", value: String(max(1, page))), URLQueryItem(name: "limit", value: "20")]
        default: return []
        }
    }

    var body: Data? {
        get throws {
            guard case .registerFree(_, let childID) = self else { return nil }
            return try JSONSerialization.data(withJSONObject: ["childId": EndpointIdentifier.validated(childID), "hasAgreedTerms": "true"])
        }
    }

    var logDetails: String {
        guard case .list(let filter, let page) = self else { return "" }
        return " filter=\(filter.rawValue) page=\(max(1, page))"
    }

    var failureMessage: String {
        if case .list = self { return "Unable to load events. Please try again." }
        return "Unable to load event information. Please try again."
    }
}
