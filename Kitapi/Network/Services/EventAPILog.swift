import Foundation

/// Debug diagnostics; request headers are omitted and JSON credentials are redacted.
enum EventAPILog {
    static func write(_ message: String) {
        #if DEBUG
        LogFile.debugMessage(debug: message)
        #endif
    }

    static func responseBody(_ data: Data) -> String {
        guard !data.isEmpty else { return "<empty response>" }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
              let formatted = try? JSONSerialization.data(withJSONObject: redact(object), options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]),
              let text = String(data: formatted, encoding: .utf8) else {
            return String(data: data, encoding: .utf8) ?? "<non-text response: \(data.count) bytes>"
        }
        return text
    }

    private static func redact(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, item in
                let key = item.key.lowercased().filter { $0.isLetter }
                let sensitive = key.contains("token") || key.contains("password") || key.contains("secret") || key == "authorization" || key == "razorpaysignature"
                result[item.key] = sensitive ? "<redacted>" : redact(item.value)
            }
        }
        if let array = value as? [Any] { return array.map(redact) }
        return value
    }

    static func errorSummary(_ error: any Error) -> String {
        if let error = error as? NetworkError {
            switch error {
            case .apiError(let response), .authenticationFailed(let response):
                return errorSummary(EventServiceError.server(response.message ?? "Unsuccessful API response"))
            case .requestFailed(let underlying): return errorSummary(underlying)
            case .invalidURL: return "invalid URL"
            case .invalidResponse: return "invalid response"
            case .decodingFailed: return "response decoding failed"
            case .unknown: return "unknown network error"
            }
        }
        if let error = error as? DecodingError {
            switch error {
            case .keyNotFound(let key, let context):
                return "decoding missingKey=\(path(context.codingPath + [key]))"
            case .typeMismatch(_, let context):
                return "decoding typeMismatch path=\(path(context.codingPath))"
            case .valueNotFound(_, let context):
                return "decoding nullValue path=\(path(context.codingPath))"
            case .dataCorrupted(let context):
                return "decoding invalidData path=\(path(context.codingPath))"
            @unknown default: return "decoding unknown"
            }
        }
        if error is CancellationError { return "cancelled" }
        if let error = error as? URLError { return "network code=\(error.code.rawValue) \(error.localizedDescription)" }
        return error.localizedDescription.replacingOccurrences(of: "\n", with: " ").prefix(200).description
    }

    private static func path(_ keys: [any CodingKey]) -> String {
        keys.isEmpty ? "<root>" : keys.map(\.stringValue).joined(separator: ".")
    }
}
