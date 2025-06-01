//
//  BaseRequest.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

/// Protocol defining the structure of all network requests in the application
/// Provides a standardized way to create and configure network requests
protocol BaseRequest {
    /// The type of response expected from this request
    /// Must conform to Decodable to enable automatic JSON decoding
    associatedtype Response: Decodable
    
    /// The type of body data to be sent with this request
    /// Must conform to Encodable to enable automatic JSON encoding
    associatedtype Body: Encodable

    /// The base URL for the API
    /// This is typically the root URL of the API service
    var baseUrl: String { get }

    /// The specific endpoint path for this request
    /// This will be appended to the base URL
    var path: String { get }

    /// The HTTP method to be used for this request
    var method: HTTPMethod { get }

    /// Optional query parameters for GET and DELETE requests
    /// These will be encoded into the URL query string
    var queryParameters: [String: Any]? { get }

    /// Optional body data for POST and PUT requests
    /// This will be encoded as JSON in the request body
    var body: Body? { get }

    /// Optional custom headers for the request
    /// These will be added to the default headers
    var headers: [String: String]? { get }
}

// MARK: - Default Implementations

extension BaseRequest {
    /// Default base URL for the OpenSky Network API
    var baseUrl: String {
        return "https://opensky-network.org/api/"
    }

    /// Default implementation returns nil for query parameters
    var queryParameters: [String: Any]? {
        return nil
    }

    /// Default implementation returns nil for body
    var body: Body? {
        return nil
    }

    /// Default implementation returns nil for headers
    var headers: [String: String]? {
        return nil
    }
}

// MARK: - URLRequest Creation

extension BaseRequest {
    /// Creates a URLRequest from the request configuration
    /// - Returns: A configured URLRequest ready to be sent, or nil if the request could not be created
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

