import Foundation

@MainActor
protocol APIClientProtocol {
    func request(for endpoint: any APIEndpoint) throws -> URLRequest
    func execute<Value: Decodable>(_ endpoint: any APIEndpoint, describeResult: ((Value) -> String)?) async throws -> Value
}

extension APIClientProtocol {
    func execute<Value: Decodable>(_ endpoint: any APIEndpoint) async throws -> Value {
        try await execute(endpoint, describeResult: nil)
    }
}
