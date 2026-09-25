//
//  NetworkService.swift
//  Kitapi
//
//  Created by Suneel on 13/04/26.
//

import Foundation
import UIKit



class APIClient {
    
    static func callAPIWithRawData<T: Decodable> (url: String, method: HTTPMethod = .get, body: Data? = nil, headers: [String: String] = [:], tokenScope: TokenScope = .parent)  async -> (APIResponse<T>) {
        
        guard let url = URL(string: url) else {
            return APIResponse(data: nil, error: .invalidURL, statusCode: nil)
        }
        LogFile.debugMessage(debug: "URL--->", value: url)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
            print("Request Body:", String(data: body, encoding: .utf8) ?? "")
        }
        
        if let tokenVal = AppUserDefaults.authorizationToken {
            request.setValue("Bearer " + tokenVal, forHTTPHeaderField: "Authorization")
            LogFile.debugMessage(debug: "token", value: tokenVal)
        }
        
//        switch tokenScope {
//            case .parent:
//                if let tokenVal = AppUserDefaults.authorizationToken {
//                    request.setValue("Bearer " + tokenVal, forHTTPHeaderField: "Authorization")
//                    LogFile.debugMessage(debug: " parent token", value: tokenVal)
//                }
//            case .child:
//                if let tokenVal = ChildSessionManager.shared.currentChildModeToken {
//                    request.setValue("Bearer " + tokenVal, forHTTPHeaderField: "Authorization")
//                    LogFile.debugMessage(debug: "child token", value: tokenVal)
//                }
//            case .none:
//                break
//            }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return APIResponse(data: nil, error: .invalidResponse, statusCode: nil)
            }
            LogFile.debugMessage(debug: "httpResponse", value: httpResponse)
            let statusCode = httpResponse.statusCode
            
            if (200...299).contains(statusCode) {
                let errorString = String(data: data, encoding: .utf8)
                print("Backend Response:", errorString ?? "nil")
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    return APIResponse(data: decodedData, error: nil, statusCode: statusCode)
                } catch let error {
                    LogFile.debugMessage(debug: "Decodable issue --->", value: error)
                    return APIResponse(data: nil, error: .decodingFailed, statusCode: statusCode)
                }
            } else if (statusCode == 401) || (statusCode == 403) {
                let errorResponse = try JSONDecoder().decode(APIError.self, from: data)
                return APIResponse(data: nil, error: .authenticationFailed(errorResponse), statusCode: statusCode)
                
            } else {
                // Try to decode the error response
                do {
                    let errorResponse = try JSONDecoder().decode(APIError.self, from: data)
                    return APIResponse(data: nil, error: .apiError(errorResponse), statusCode: statusCode)
                    
                } catch {
                    // If we can't decode the error, return a generic error
                    let apiError = APIError(success: false, message: "Unknown API Error")
                    return APIResponse(data: nil, error: .apiError(apiError), statusCode: statusCode)
                }
            }
        } catch {
            return APIResponse(data: nil, error: .requestFailed(error), statusCode: nil)
        }
    }
    
    
    // MARK: - Form Data Method
    
    
    static func callAPIWithFormData<T: Decodable>(
        url: String,
        method: HTTPMethod = .post,
        parameters: [String: Any],
        headers: [String: String] = [:]
    ) async -> (APIResponse<T>) {
        
        guard let url = URL(string: url) else {
            return APIResponse(data: nil, error: .invalidURL, statusCode: nil)
        }
        
        LogFile.debugMessage(debug: "URL--->", value: url)
        LogFile.debugMessage(debug: "Parameters--->", value: parameters)
        
        // Create boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = self.createFormDataBody(parameters: parameters, boundary: boundary)
        
        if let tokenVal = AppUserDefaults.authorizationToken {
            request.setValue("Bearer " + tokenVal, forHTTPHeaderField: "Authorization")
        }
        
        LogFile.debugMessage(debug: "Request Body:", value: String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return APIResponse(data: nil, error: .invalidResponse, statusCode: nil)
            }
            
            LogFile.debugMessage(debug: "httpResponse", value: httpResponse)
            LogFile.debugMessage(debug: "Response Data", value: String(data: data, encoding: .utf8) ?? "")
            
            let statusCode = httpResponse.statusCode
            
            if (200...299).contains(statusCode) {
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    return APIResponse(data: decodedData, error: nil, statusCode: statusCode)
                } catch let error {
                    LogFile.debugMessage(debug: "Decoding Error --->", value: error)
                    return APIResponse(data: nil, error: .decodingFailed, statusCode: statusCode)
                }
            }
            else if (statusCode == 401) || (statusCode == 403) {
                let errorResponse = try JSONDecoder().decode(APIError.self, from: data)
                return APIResponse(data: nil, error: .authenticationFailed(errorResponse), statusCode: statusCode)
            } else {
                // Try to decode error response
                do {
                    let errorResponse = try JSONDecoder().decode(APIError.self, from: data)
                    LogFile.debugMessage(debug: "erroeRespnse", value: errorResponse)
                    return APIResponse(data: nil, error: .apiError(errorResponse), statusCode: statusCode)
                } catch {
                    let apiError = APIError(success: false, message: "Server Error: \(statusCode)")
                    return APIResponse(data: nil, error: .apiError(apiError), statusCode: statusCode)
                }
            }
        } catch {
            LogFile.debugMessage(debug: "Network Error --->", value: error)
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
