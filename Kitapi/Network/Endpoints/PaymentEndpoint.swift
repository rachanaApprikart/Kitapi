import Foundation

enum PaymentEndpoint: APIEndpoint {
    case registrations(page: Int)
    case createRegistration(childID: String, batchID: String, grade: String?, school: String?)
    case paymentOrder(registrationID: String)
    case verifyPayment(registrationID: String, proof: EventPaymentProof)
    case registration(id: String)

    var path: String {
        get throws {
            switch self {
            case .registrations: return "/api/event-registrations/my"
            case .createRegistration: return "/api/event-registrations"
            case .paymentOrder(let id): return "/api/event-registrations/\(try EndpointIdentifier.validated(id))/payment-order"
            case .verifyPayment(let id, _): return "/api/event-registrations/\(try EndpointIdentifier.validated(id))/verify-payment"
            case .registration(let id): return "/api/event-registrations/\(try EndpointIdentifier.validated(id))"
            }
        }
    }

    var method: HTTPMethod {
        switch self {
        case .registrations, .registration: return .get
        default: return .post
        }
    }

    var queryItems: [URLQueryItem] {
        guard case .registrations(let page) = self else { return [] }
        return [URLQueryItem(name: "page", value: String(max(1, page))), URLQueryItem(name: "limit", value: "50")]
    }

    var body: Data? {
        get throws {
            switch self {
            case .createRegistration(let childID, let batchID, let grade, let school):
                var parameters = ["childId": try EndpointIdentifier.validated(childID), "eventBatchId": try EndpointIdentifier.validated(batchID), "hasAgreedConsent": "true"]
                if let grade, !grade.isEmpty { parameters["grade"] = grade }
                if let school, !school.isEmpty { parameters["schoolName"] = school }
                return try JSONSerialization.data(withJSONObject: parameters)
            case .verifyPayment(_, let proof): return try JSONEncoder().encode(proof)
            default: return nil
            }
        }
    }

    var acceptsConflictResponse: Bool {
        if case .createRegistration = self { return true }
        return false
    }
}
