import Foundation

@MainActor
protocol APIEndpoint {
    var path: String { get throws }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var body: Data? { get throws }
    var acceptsConflictResponse: Bool { get }
    var logDetails: String { get }
    var failureMessage: String { get }
}

extension APIEndpoint {
    var queryItems: [URLQueryItem] { [] }
    var body: Data? { get throws { nil } }
    var acceptsConflictResponse: Bool { false }
    var logDetails: String { "" }
    var failureMessage: String { "Unable to load event information. Please try again." }
}

enum EndpointIdentifier {
    static func validated(_ value: String) throws -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard !value.isEmpty, value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { throw EventServiceError.invalidURL }
        return value
    }
}
