//
//  BaseRequest.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

// Protocol for all network requests
protocol BaseRequest {
    associatedtype Response: Decodable
    associatedtype Body: Encodable

    // Base URL for the API
    var baseUrl: String { get }

    // Endpoint path
    var path: String { get }

    // HTTP method for the request
    var method: HTTPMethod { get }

    // Query parameters for GET and DELETE requests
    var queryParameters: [String: Any]? { get }

    // Body parameters for POST and PUT requests
    var body: Body? { get }

    // Headers for the request
    var headers: [String: String]? { get }
}

// MARK: - Default Implementations
extension BaseRequest {
    var baseUrl: String {
        return "https://opensky-network.org/api/"
    }

    var queryParameters: [String: Any]? {
        return nil
    }

    var body: Body? {
        return nil
    }

    var headers: [String: String]? {
        return nil
    }
}

// MARK: - URLRequest Creation
extension BaseRequest {
    var asURLRequest: URLRequest? {
        var urlComponents = URLComponents(string: baseUrl + path)

        // Add parameters as query string for GET and DELETE requests
        if (method == .GET || method == .DELETE), let parameters = queryParameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }

        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)

        // Set HTTP method
        request.httpMethod = method.rawValue

        // Set default headers
        var defaultHeaders = [
            "Accept": "application/json"
        ]

        // Add custom headers
        if let customHeaders = headers {
            defaultHeaders.merge(customHeaders) { _, new in new }
        }

        // Set all headers
        defaultHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Add body for POST and PUT requests
        if (method == .POST || method == .PUT), let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
                request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            } catch {
                return nil
            }
        }

        return request
    }
}

