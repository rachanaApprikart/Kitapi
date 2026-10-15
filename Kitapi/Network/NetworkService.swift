//
//  NetworkService.swift
//  Kitapi
//
//  Created by Suneel on 13/04/26.
//

import Foundation
import UIKit

class APIClient: APIClientProtocol {
    var session: URLSession
    var baseURL: String
    var tokenProvider: () -> String?
    var logger: (String) -> Void
    private let authenticationFailureHandler: () -> Void

    init(session: URLSession = .shared,
         baseURL: String = BASE_URL,
         tokenProvider: @escaping () -> String? = { AppUserDefaults.authorizationToken },
         logger: @escaping (String) -> Void = { EventAPILog.write($0) },
         authenticationFailureHandler: (() -> Void)? = nil) {
        self.session = session
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.logger = logger
        self.authenticationFailureHandler = authenticationFailureHandler ?? {
            if AppUserDefaults.authorizationToken != nil {
                SessionManager.shared.handleAuthenticationFailure()
            }
        }
    }

    nonisolated deinit {}

    // MARK: - Endpoint API

    func request(for endpoint: any APIEndpoint) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + (try endpoint.path)) else { throw EventServiceError.invalidURL }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        guard let url = components.url, url.scheme == "https", url.host != nil else { throw EventServiceError.invalidURL }
        guard let token = tokenProvider(), !token.isEmpty else { throw EventServiceError.signInRequired }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = try endpoint.body
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        return request
    }

    func execute<Value: Decodable>(_ endpoint: any APIEndpoint, describeResult: ((Value) -> String)? = nil) async throws -> Value {
        let context = "[EventAPI][\(UUID().uuidString.prefix(8))] \(endpoint.method.rawValue) \((try? endpoint.path) ?? "<invalid endpoint>")\(endpoint.logDetails)"
        let start = ProcessInfo.processInfo.systemUptime
        var status: Int?
        logger("\(context) REQUEST")
        do {
            let request = try request(for: endpoint)
            logger("\(context) URL \(request.url?.absoluteString ?? "<invalid>")")
            let result: APIResponse<EventAPIEnvelope<Value>> = await performJSONRequest(
                request,
                acceptConflict: endpoint.acceptsConflictResponse,
                forbiddenMeansAuthenticationFailure: false,
                preserveDecodingErrors: true,
                context: context
            )
            status = result.statusCode
            if let error = result.error {
                switch error {
                case .invalidURL: throw EventServiceError.invalidURL
                case .authenticationFailed: throw EventServiceError.signInRequired
                case .apiError(let error): throw EventServiceError.server(error.message ?? endpoint.failureMessage)
                case .requestFailed(let error): throw error
                case .invalidResponse, .decodingFailed, .unknown: throw EventServiceError.invalidResponse
                }
            }
            let acceptedConflict = endpoint.acceptsConflictResponse && status == 409
            guard let envelope = result.data, envelope.success || acceptedConflict, let value = envelope.data else {
                throw EventServiceError.server(result.data?.message ?? endpoint.failureMessage)
            }
            let description = describeResult?(value) ?? ""
            logger("\(context) SUCCESS \(description.isEmpty ? "" : description + " ")durationMs=\(Int((ProcessInfo.processInfo.systemUptime - start) * 1000))")
            return value
        } catch {
            let cancelled = error is CancellationError || (error as? URLError)?.code == .cancelled
            logger("\(context) \(cancelled ? "CANCELLED" : "FAILED") status=\(status.map(String.init) ?? "none") durationMs=\(Int((ProcessInfo.processInfo.systemUptime - start) * 1000)) reason=\(EventAPILog.errorSummary(error))")
            throw error
        }
    }

    // MARK: - Existing JSON API (call sites remain compatible)

    static func callAPIWithRawData<T: Decodable>(
        url: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String] = [:],
        tokenScope: TokenScope = .parent,
        client: APIClient? = nil
    ) async -> APIResponse<T> {
        guard let url = URL(string: url) else { return APIResponse(data: nil, error: .invalidURL, statusCode: nil) }
        let client = client ?? APIClient()
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Preserve the existing parent-token behavior for legacy call sites.
        if let token = client.tokenProvider() { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return await client.performJSONRequest(request)
    }

    // MARK: - Existing multipart API

    static func callAPIWithFormData<T: Decodable>(
        url: String,
        method: HTTPMethod = .post,
        parameters: [String: Any],
        headers: [String: String] = [:],
        client: APIClient? = nil
    ) async -> APIResponse<T> {
        guard let url = URL(string: url) else { return APIResponse(data: nil, error: .invalidURL, statusCode: nil) }
        let client = client ?? APIClient()
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        request.httpBody = createFormDataBody(parameters: parameters, boundary: boundary)
        if let token = client.tokenProvider() { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return await client.performJSONRequest(request, fallbackError: { "Server Error: \($0)" })
    }

    // MARK: - Shared transport and response decoding

    private func performJSONRequest<T: Decodable>(
        _ request: URLRequest,
        acceptConflict: Bool = false,
        forbiddenMeansAuthenticationFailure: Bool = true,
        preserveDecodingErrors: Bool = false,
        context: String? = nil,
        fallbackError: (Int) -> String = { _ in "Unknown API Error" }
    ) async -> APIResponse<T> {
        let logContext = context ?? "[API][\(UUID().uuidString.prefix(8))] \(request.httpMethod ?? "GET") \(request.url?.path ?? "<invalid>")"
        if context == nil {
            logger("\(logContext) REQUEST URL \(request.url?.absoluteString ?? "<invalid>")")
            #if DEBUG
            // Multipart bodies may contain binary data. Never dump them or authorization headers.
            if request.value(forHTTPHeaderField: "Content-Type") == "application/json", let body = request.httpBody {
                logger("\(logContext) REQUEST BODY\n\(EventAPILog.responseBody(body))")
            }
            #endif
        }
        do {
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else {
                return APIResponse(data: nil, error: .invalidResponse, statusCode: nil)
            }
            let status = http.statusCode
            logger("\(logContext) RESPONSE status=\(status) bytes=\(data.count)")
            #if DEBUG
            logger("\(logContext) RESPONSE BODY\n\(EventAPILog.responseBody(data))")
            #endif
            if (200...299).contains(status) || (acceptConflict && status == 409) {
                do {
                    return APIResponse(data: try JSONDecoder().decode(T.self, from: data), error: nil, statusCode: status)
                } catch {
                    logger("\(logContext) FAILED decoding=\(EventAPILog.errorSummary(error))")
                    return APIResponse(data: nil, error: preserveDecodingErrors ? .requestFailed(error) : .decodingFailed, statusCode: status)
                }
            }
            let error = (try? JSONDecoder().decode(APIError.self, from: data)) ?? APIError(success: false, message: fallbackError(status))
            if status == 401 || (status == 403 && forbiddenMeansAuthenticationFailure) {
                authenticationFailureHandler()
                return APIResponse(data: nil, error: .authenticationFailed(error), statusCode: status)
            }
            return APIResponse(data: nil, error: .apiError(error), statusCode: status)
        } catch {
            logger("\(logContext) FAILED reason=\(EventAPILog.errorSummary(error))")
            return APIResponse(data: nil, error: .requestFailed(error), statusCode: nil)
        }
    }

    //Modified on 28 may
    
    // MARK: - Helper: Create Form Data Body
    private static func createFormDataBody(parameters: [String: Any], boundary: String) -> Data {
        var body = Data()
        
        for (key, value) in parameters {
            // ✅ Handle UIImage as binary file part
            if let image = value as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key).jpg\"\r\n")
                body.append("Content-Type: image/jpeg\r\n\r\n")
                body.append(imageData)
                body.append("\r\n")
            }
            else if let fileURL = value as? URL, let fileData = try? Data(contentsOf: fileURL) {
                let filename = fileURL.lastPathComponent
                let mimeType = fileURL.pathExtension == "m4a" ? "audio/m4a" : "audio/mpeg"
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
                body.append("Content-Type: \(mimeType)\r\n\r\n")
                body.append(fileData)
                body.append("\r\n")
            }
            // ✅ NEW: Handle arrays — one part per element, same field name
            else if let arrayValue = value as? [Any] {
                for item in arrayValue {
                    body.append("--\(boundary)\r\n")
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                    body.append("\(item)\r\n")
                }
            }
            // ✅ Handle all other types as text
            else {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
}

  // MARK: - Data Extension
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}



struct APIResponse<T: Decodable> {
    let data: T?
    let error: NetworkError?
    let statusCode: Int?
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum TokenScope {
    case parent
    case child
    case none
}

