//
//  NetworkLogger.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 31.05.2025.
//

import Foundation
import Alamofire

/// A utility class for logging network requests and responses
/// This logger provides detailed information about network operations including:
/// - Request/Response URLs
/// - HTTP Methods
/// - Headers
/// - Request/Response Bodies
/// - Error Information
final class NetworkLogger {
    /// Logs the details of a network request
    /// - Parameters:
    ///   - request: The URLRequest to be logged
    ///   - requestId: Optional unique identifier for the request, useful for tracking request-response pairs
    static func logRequest(_ request: URLRequest, requestId: String? = nil) {
        print("\n🚀 REQUEST LOG 🚀")
        if let requestId = requestId {
            print("Request ID: \(requestId)")
        }
        print("URL: \(request.url?.absoluteString ?? "")")
        print("Method: \(request.httpMethod ?? "")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")

        if let body = request.httpBody,
            let jsonString = formatJSON(from: body) {
            print("Body: \(jsonString)")
        }
        print("------------------------\n")
    }

    /// Logs the details of a network response
    /// - Parameters:
    ///   - response: The HTTPURLResponse containing status code and headers
    ///   - data: The response data received from the server
    ///   - error: Any error that occurred during the request
    ///   - requestId: Optional unique identifier matching the original request
    static func logResponse(response: HTTPURLResponse?, data: Data?, error: Error?, requestId: String? = nil) {
        print("\n📥 RESPONSE LOG 📥")
        if let requestId = requestId {
            print("Request ID: \(requestId)")
        }
        print("URL: \(response?.url?.absoluteString ?? "")")
        print("Status Code: \(response?.statusCode ?? 0)")

        if let headers = response?.allHeaderFields as? [String: Any] {
            print("Headers: \(headers)")
        }

        if let data = data,
            let jsonString = formatJSON(from: data) {
            print("Response Data:\n\(jsonString)")
        }

        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
        print("------------------------\n")
    }

    // MARK: - Helper Methods
    
    /// Formats JSON data into a pretty-printed string
    /// - Parameter data: The data to be formatted
    /// - Returns: A formatted JSON string if the data is valid JSON, otherwise returns the raw string representation
    private static func formatJSON(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
            let prettyString = String(data: prettyData, encoding: .utf8) else {
            return String(data: data, encoding: .utf8)
        }
        return prettyString
    }
}
